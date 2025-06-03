import 'package:dwaya_app/models/pharmacy.dart';
import 'package:dwaya_app/services/places_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dwaya_app/utils/connectivity_helper.dart';
class PharmacyProvider with ChangeNotifier {
  final PlacesService _placesService = PlacesService();
  final ConnectivityHelper _connectivityHelper = ConnectivityHelper();
  List<Pharmacy> _pharmacies = [];
  bool _isLoading = false;
  String? _errorMessage;
  LatLng? _lastSearchLocation;
  bool _isOfflineMode = false;
  List<Pharmacy> get pharmacies => _pharmacies;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  LatLng? get lastSearchLocation => _lastSearchLocation;
  bool get isOfflineMode => _isOfflineMode;
  PharmacyProvider() {
    _connectivityHelper.addListener(_onConnectivityChanged);
    _isOfflineMode = _connectivityHelper.isOffline;
  }
  void _onConnectivityChanged() {
    final bool wasOffline = _isOfflineMode;
    _isOfflineMode = _connectivityHelper.isOffline;
    if (wasOffline && !_isOfflineMode && _lastSearchLocation != null) {
      fetchAndSetPharmacies(_lastSearchLocation!, showLoading: false);
    }
    if (wasOffline != _isOfflineMode) {
      notifyListeners();
    }
  }
  Future<void> fetchAndSetPharmacies(
    LatLng location, {
    int radius = 5000,
    bool forceRefresh = false,
    bool showLoading = true,
  }) async {
    if (_isLoading || (!forceRefresh && _isSameLocation(location))) {
      return;
    }
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      if (_connectivityHelper.isOffline && !forceRefresh) {
        _isOfflineMode = true;
        final cachedPharmacies = await _placesService.fetchNearbyPharmacies(
          location,
          radius: radius,
          forceRefresh: false,
          offlineMode: true,
        );
        if (cachedPharmacies.isNotEmpty) {
          final processedPharmacies = _processPharmacies(cachedPharmacies, location);
          _pharmacies = processedPharmacies;
          _lastSearchLocation = location;
          _errorMessage = 'Showing cached results (offline mode)';
        } else {
          _errorMessage = 'No cached results available. Connect to the internet and try again.';
        }
      } else {
        _isOfflineMode = false;
        final fetchedPharmacies = await _placesService.fetchNearbyPharmacies(
          location,
          radius: radius,
          forceRefresh: forceRefresh,
        );
        final processedPharmacies = _processPharmacies(fetchedPharmacies, location);
        _pharmacies = processedPharmacies;
        _lastSearchLocation = location;
        _errorMessage = null;
      }
    } catch (e) {
      try {
        final cachedPharmacies = await _placesService.fetchNearbyPharmacies(
          location,
          radius: radius,
          offlineMode: true,
        );
        if (cachedPharmacies.isNotEmpty) {
          final processedPharmacies = _processPharmacies(cachedPharmacies, location);
          _pharmacies = processedPharmacies;
          _lastSearchLocation = location;
          _errorMessage = 'Showing cached results. Failed to refresh: $e';
        } else {
          _errorMessage = 'Failed to load pharmacies: $e';
          _pharmacies = [];
        }
      } catch (_) {
        _errorMessage = 'Failed to load pharmacies: $e';
        _pharmacies = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  List<Pharmacy> _processPharmacies(List<Pharmacy> pharmacies, LatLng location) {
    final processed = pharmacies.map((pharmacy) {
      if (pharmacy.latitude != null && pharmacy.longitude != null) {
        final distanceInMeters = Geolocator.distanceBetween(
          location.latitude,
          location.longitude,
          pharmacy.latitude!,
          pharmacy.longitude!,
        );
        return pharmacy.copyWith(distance: distanceInMeters);
      }
      return pharmacy;
    }).toList();
    processed.sort((a, b) =>
      (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity)
    );
    return processed;
  }
  bool _isSameLocation(LatLng newLocation) {
    if (_lastSearchLocation == null) return false;
    final distance = Geolocator.distanceBetween(
      _lastSearchLocation!.latitude,
      _lastSearchLocation!.longitude,
      newLocation.latitude,
      newLocation.longitude,
    );
    return distance < 10;
  }
  void updatePharmacy(String pharmacyId, Pharmacy updatedPharmacy) {
    final index = _pharmacies.indexWhere((p) => p.id == pharmacyId);
    if (index != -1) {
      _pharmacies[index] = updatedPharmacy;
      notifyListeners();
    }
  }
  void clearPharmacies() {
    _pharmacies = [];
    _errorMessage = null;
    _lastSearchLocation = null;
    notifyListeners();
  }
  Future<void> refreshResults() async {
    if (_lastSearchLocation == null) return;
    await fetchAndSetPharmacies(_lastSearchLocation!, forceRefresh: true);
  }
  List<Pharmacy> searchPharmacies(String query) {
    if (query.trim().isEmpty) return _pharmacies;
    final normalizedQuery = query.toLowerCase().trim();
    return _pharmacies.where((pharmacy) {
      return pharmacy.name.toLowerCase().contains(normalizedQuery) ||
             pharmacy.address.toLowerCase().contains(normalizedQuery);
    }).toList();
  }
  @override
  void dispose() {
    _connectivityHelper.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}