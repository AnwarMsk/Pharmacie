import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwaya_app/models/pharmacy.dart';
class FavoritesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _favoritesSubscription;
  Set<String> _favoritePharmacyIds = {};
  bool _isLoading = false;
  String? _currentUserId;
  bool _isAuthenticated = false;
  final Map<String, bool> _favoriteCache = {};
  final Map<String, bool> _pendingFavoriteUpdates = {};
  Timer? _batchUpdateTimer;
  static const Duration _batchDelay = Duration(milliseconds: 500);
  bool _localCacheInitialized = false;
  Set<String> get favoritePharmacyIds => _favoritePharmacyIds;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isAuthenticated && _currentUserId != null;
  void updateAuth(bool isAuthenticated, String? userId) {
    final bool stateChanged = _isAuthenticated != isAuthenticated || _currentUserId != userId;
    _isAuthenticated = isAuthenticated;
    _currentUserId = userId;
    if (stateChanged) {
      if (isAuthenticated && userId != null) {
        _setupFavoritesListener();
      } else {
        _cancelSubscriptions();
        _favoritePharmacyIds = {};
        _favoriteCache.clear();
        _loadFromLocalCache();
        notifyListeners();
      }
    }
  }
  bool isFavorite(String pharmacyId) {
    if (_favoriteCache.containsKey(pharmacyId)) {
      return _favoriteCache[pharmacyId]!;
    }
    if (_pendingFavoriteUpdates.containsKey(pharmacyId)) {
      return _pendingFavoriteUpdates[pharmacyId]!;
    }
    final isFav = _favoritePharmacyIds.contains(pharmacyId);
    _favoriteCache[pharmacyId] = isFav;
    return isFav;
  }
  void _setupFavoritesListener() {
    _cancelSubscriptions();
    if (!_isAuthenticated || _currentUserId == null) {
      _loadFromLocalCache();
      return;
    }
    _isLoading = true;
    notifyListeners();
    final userRef = _firestore.collection('users').doc(_currentUserId);
    _favoritesSubscription = userRef.snapshots().listen(
      (snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data() as Map<String, dynamic>;
          final idsFromFirestore = data['favoritePharmacyIds'] as List?;
          if (idsFromFirestore != null) {
            _favoritePharmacyIds = idsFromFirestore.map((id) => id.toString()).toSet();
            _favoriteCache.clear();
            for (var id in _favoritePharmacyIds) {
              _favoriteCache[id] = true;
            }
            _saveToLocalCache();
          } else {
            _favoritePharmacyIds = {};
            _favoriteCache.clear();
          }
        } else {
          _favoritePharmacyIds = {};
          _favoriteCache.clear();
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _loadFromLocalCache();
        notifyListeners();
      }
    );
  }
  Future<void> _saveToLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favoritePharmacyIds', _favoritePharmacyIds.toList());
    } catch (e) {
    }
  }
  Future<void> _loadFromLocalCache() async {
    if (_localCacheInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedFavorites = prefs.getStringList('favoritePharmacyIds');
      if (cachedFavorites != null && cachedFavorites.isNotEmpty) {
        _favoritePharmacyIds = cachedFavorites.toSet();
        _favoriteCache.clear();
        for (var id in _favoritePharmacyIds) {
          _favoriteCache[id] = true;
        }
        _localCacheInitialized = true;
        notifyListeners();
      }
    } catch (e) {
    }
  }
  void _cancelSubscriptions() {
    _favoritesSubscription?.cancel();
    _favoritesSubscription = null;
    _batchUpdateTimer?.cancel();
    _batchUpdateTimer = null;
  }
  Future<void> toggleFavorite(String pharmacyId) async {
    final bool isCurrentlyFavorite = isFavorite(pharmacyId);
    if (isCurrentlyFavorite) {
      _favoritePharmacyIds.remove(pharmacyId);
      _favoriteCache[pharmacyId] = false;
    } else {
      _favoritePharmacyIds.add(pharmacyId);
      _favoriteCache[pharmacyId] = true;
    }
    notifyListeners();
    _saveToLocalCache();
    if (!isLoggedIn) return;
    _pendingFavoriteUpdates[pharmacyId] = !isCurrentlyFavorite;
    _batchUpdateTimer?.cancel();
    _batchUpdateTimer = Timer(_batchDelay, () {
      _processPendingUpdates();
    });
  }
  Future<void> _processPendingUpdates() async {
    if (_pendingFavoriteUpdates.isEmpty || !isLoggedIn) return;
    final userRef = _firestore.collection('users').doc(_currentUserId);
    final pendingAdds = <String>[];
    final pendingRemoves = <String>[];
    _pendingFavoriteUpdates.forEach((id, isFavorite) {
      if (isFavorite) {
        pendingAdds.add(id);
      } else {
        pendingRemoves.add(id);
      }
    });
    _pendingFavoriteUpdates.clear();
    try {
      if (pendingAdds.length + pendingRemoves.length > 1) {
        final batch = _firestore.batch();
        if (pendingAdds.isNotEmpty) {
          batch.update(userRef, {
            'favoritePharmacyIds': FieldValue.arrayUnion(pendingAdds)
          });
        }
        if (pendingRemoves.isNotEmpty) {
          batch.update(userRef, {
            'favoritePharmacyIds': FieldValue.arrayRemove(pendingRemoves)
          });
        }
        await batch.commit();
      }
      else if (pendingAdds.isNotEmpty) {
        await userRef.set({
          'favoritePharmacyIds': FieldValue.arrayUnion(pendingAdds)
        }, SetOptions(merge: true));
      } else if (pendingRemoves.isNotEmpty) {
        await userRef.set({
          'favoritePharmacyIds': FieldValue.arrayRemove(pendingRemoves)
        }, SetOptions(merge: true));
      }
    } catch (e) {
      for (var id in pendingAdds) {
        _favoritePharmacyIds.remove(id);
        _favoriteCache[id] = false;
      }
      for (var id in pendingRemoves) {
        _favoritePharmacyIds.add(id);
        _favoriteCache[id] = true;
      }
      notifyListeners();
    }
  }
  List<Pharmacy> markFavorites(List<Pharmacy> pharmacies) {
    return pharmacies.map((pharmacy) {
      if (isFavorite(pharmacy.id)) {
        return pharmacy;
      }
      return pharmacy;
    }).toList();
  }
  Future<void> syncPendingUpdates() async {
    _batchUpdateTimer?.cancel();
    await _processPendingUpdates();
  }
  @override
  void dispose() {
    _batchUpdateTimer?.cancel();
    _processPendingUpdates();
    _cancelSubscriptions();
    super.dispose();
  }
}