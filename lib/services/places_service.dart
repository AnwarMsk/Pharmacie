import 'dart:convert';
import 'package:dwaya_app/models/pharmacy.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:dwaya_app/models/directions_result.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
class PlacesService {
  final Map<String, dynamic> _memoryCache = {};
  static const int _maxCacheItems = 20;
  final Duration _cacheExpiration = const Duration(minutes: 30);
  final String _proxyBaseUrl = const String.fromEnvironment(
    'PROXY_BASE_URL',
    defaultValue: 'https:
  );
  final http.Client _client = http.Client();
  static final PlacesService _instance = PlacesService._internal();
  factory PlacesService() => _instance;
  PlacesService._internal();
  Future<List<Pharmacy>> fetchNearbyPharmacies(
    LatLng location, {
    int radius = 5000,
    bool forceRefresh = false,
    bool offlineMode = false,
  }) async {
    final cacheKey = 'pharmacies_${location.latitude}_${location.longitude}_$radius';
    if (!forceRefresh && _memoryCache.containsKey(cacheKey)) {
      final cachedData = _memoryCache[cacheKey];
      final DateTime timestamp = cachedData['timestamp'];
      if (DateTime.now().difference(timestamp) < _cacheExpiration) {
        return cachedData['data'] as List<Pharmacy>;
      }
      _memoryCache.remove(cacheKey);
    }
    if (offlineMode) {
      final persistentData = await _loadFromPersistentCache(cacheKey);
      if (persistentData != null) {
        return persistentData;
      }
      return [];
    }
    if (!forceRefresh && await _isNetworkUnavailable()) {
      final persistentData = await _loadFromPersistentCache(cacheKey);
      if (persistentData != null) {
        return persistentData;
      }
    }
    final url = Uri.parse(_proxyBaseUrl);
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'latitude': location.latitude,
          'longitude': location.longitude,
          'radius': radius,
        }),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = json.decode(responseBody);
        if (data['results'] != null && data['results'] is List) {
          final List results = data['results'];
          final pharmacies = _parsePharmacies(results);
          _manageMemoryCacheSize();
          _memoryCache[cacheKey] = {
            'data': pharmacies,
            'timestamp': DateTime.now(),
          };
          _saveToPersistentCache(cacheKey, pharmacies);
          return pharmacies;
        } else {
          final errorMessage = data['error'] ?? 'Unknown error from proxy';
          throw Exception('Proxy Error: $errorMessage');
        }
      } else {
        throw Exception(
          'Failed to load pharmacies from proxy: ${response.statusCode}',
        );
      }
    } catch (e) {
      final persistentData = await _loadFromPersistentCache(cacheKey);
      if (persistentData != null) {
        return persistentData;
      }
      throw Exception('Failed to fetch pharmacies via proxy: $e');
    }
  }
  void _manageMemoryCacheSize() {
    if (_memoryCache.length > _maxCacheItems) {
      var entries = _memoryCache.entries.toList()
        ..sort((a, b) => (a.value['timestamp'] as DateTime)
            .compareTo(b.value['timestamp'] as DateTime));
      int toRemove = (_memoryCache.length - (_maxCacheItems * 0.75)).round();
      for (int i = 0; i < toRemove && i < entries.length; i++) {
        _memoryCache.remove(entries[i].key);
      }
    }
  }
  Future<bool> _isNetworkUnavailable() async {
    if (kIsWeb) return false;
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isEmpty || result[0].rawAddress.isEmpty;
    } on SocketException catch (_) {
      return true;
    }
  }
  Future<void> _saveToPersistentCache(String key, List<Pharmacy> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList = data.map((pharmacy) {
        return {
          'id': pharmacy.id,
          'name': pharmacy.name,
          'address': pharmacy.address,
          'isOpen': pharmacy.isOpen,
          'imageUrl': pharmacy.imageUrl,
          'latitude': pharmacy.latitude,
          'longitude': pharmacy.longitude,
          'rating': pharmacy.rating,
          'userRatingsTotal': pharmacy.userRatingsTotal,
          'phoneNumber': pharmacy.phoneNumber,
          'website': pharmacy.website,
          'openingHours': pharmacy.openingHours?.toList(),
        };
      }).toList();
      final jsonString = json.encode({
        'data': jsonList,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      await prefs.setString('cache_$key', jsonString);
    } catch (e) {
    }
  }
  Future<List<Pharmacy>?> _loadFromPersistentCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('cache_$key');
      if (jsonString == null) return null;
      final Map<String, dynamic> cacheData = json.decode(jsonString);
      final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);
      if (DateTime.now().difference(timestamp) > _cacheExpiration) {
        return null;
      }
      final List jsonList = cacheData['data'];
      return jsonList.map<Pharmacy>((item) {
        return Pharmacy(
          id: item['id'],
          name: item['name'],
          address: item['address'],
          isOpen: item['isOpen'],
          imageUrl: item['imageUrl'],
          latitude: item['latitude'],
          longitude: item['longitude'],
          rating: item['rating'],
          userRatingsTotal: item['userRatingsTotal'],
          phoneNumber: item['phoneNumber'],
          website: item['website'],
          openingHours: item['openingHours'] != null ?
              List<String>.from(item['openingHours']) : null,
        );
      }).toList();
    } catch (e) {
      return null;
    }
  }
  List<Pharmacy> _parsePharmacies(List results) {
    return results.map((place) {
      final placeData = place as Map<String, dynamic>;
      double? _parseDouble(dynamic value) {
        if (value is num) {
          return value.toDouble();
        }
        return null;
      }
      final lat = _parseDouble(placeData['latitude']);
      final lng = _parseDouble(placeData['longitude']);
      final isOpenNow = placeData['isOpen'] as bool? ?? false;
      final imageUrlFromProxy = placeData['imageUrl'] as String? ?? '';
      final rating = _parseDouble(placeData['rating']);
      final userRatingsTotal = placeData['userRatingsTotal'] as int?;
      final phoneNumber = placeData['phoneNumber'] as String?;
      final website = placeData['website'] as String?;
      final openingHoursRaw = placeData['openingHours'];
      final List<String>? openingHours = openingHoursRaw is List
          ? openingHoursRaw.map((e) => e.toString()).toList()
          : null;
      return Pharmacy(
        id: placeData['id'] as String? ?? '',
        name: placeData['name'] as String? ?? 'Unknown Pharmacy',
        address: placeData['address'] as String? ?? 'Address not available',
        latitude: lat,
        longitude: lng,
        isOpen: isOpenNow,
        imageUrl: imageUrlFromProxy,
        rating: rating,
        userRatingsTotal: userRatingsTotal,
        phoneNumber: phoneNumber,
        website: website,
        openingHours: openingHours,
      );
    }).toList();
  }
  Future<DirectionsResult?> getDirections(
    LatLng origin,
    LatLng destination, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'directions_${origin.latitude}_${origin.longitude}_${destination.latitude}_${destination.longitude}';
    if (!forceRefresh && _memoryCache.containsKey(cacheKey)) {
      final cachedData = _memoryCache[cacheKey];
      final DateTime timestamp = cachedData['timestamp'];
      if (DateTime.now().difference(timestamp) < _cacheExpiration) {
        return cachedData['data'] as DirectionsResult;
      }
      _memoryCache.remove(cacheKey);
    }
    if (!forceRefresh && await _isNetworkUnavailable()) {
      final persistentData = await _loadDirectionsFromPersistentCache(cacheKey);
      if (persistentData != null) {
        return persistentData;
      }
    }
    final url = Uri.parse('$_proxyBaseUrl/directions');
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'originLat': origin.latitude,
          'originLng': origin.longitude,
          'destinationLat': destination.latitude,
          'destinationLng': destination.longitude,
        }),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = json.decode(responseBody);
        if (data['polyline_encoded'] != null && data['bounds'] != null) {
          final boundsData = data['bounds'];
          final northeast = boundsData['northeast'];
          final southwest = boundsData['southwest'];
          if (northeast != null && southwest != null &&
              northeast['lat'] != null && northeast['lng'] != null &&
              southwest['lat'] != null && southwest['lng'] != null) {
            final bounds = LatLngBounds(
              southwest: LatLng(southwest['lat'], southwest['lng']),
              northeast: LatLng(northeast['lat'], northeast['lng']),
            );
            final result = DirectionsResult(
              encodedPolyline: data['polyline_encoded'],
              bounds: bounds,
            );
            _manageMemoryCacheSize();
            _memoryCache[cacheKey] = {
              'data': result,
              'timestamp': DateTime.now(),
            };
            _saveDirectionsToPersistentCache(cacheKey, result);
            return result;
          } else {
            throw Exception('Invalid bounds data received from directions proxy');
          }
        } else if (data['error'] != null) {
           throw Exception('Directions Proxy Error: ${data['error']}');
        } else {
           throw Exception('Invalid response format from directions proxy');
        }
      } else {
        throw Exception(
          'Failed to get directions from proxy: ${response.statusCode}',
        );
      }
    } catch (e) {
      final persistentData = await _loadDirectionsFromPersistentCache(cacheKey);
      if (persistentData != null) {
        return persistentData;
      }
      throw Exception('Failed to get directions: $e');
    }
  }
  Future<void> _saveDirectionsToPersistentCache(String key, DirectionsResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = {
        'encodedPolyline': result.encodedPolyline,
        'bounds': {
          'southwest': {
            'lat': result.bounds.southwest.latitude,
            'lng': result.bounds.southwest.longitude,
          },
          'northeast': {
            'lat': result.bounds.northeast.latitude,
            'lng': result.bounds.northeast.longitude,
          },
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString('directions_$key', json.encode(jsonData));
    } catch (e) {
    }
  }
  Future<DirectionsResult?> _loadDirectionsFromPersistentCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('directions_$key');
      if (jsonString == null) return null;
      final Map<String, dynamic> data = json.decode(jsonString);
      final timestamp = DateTime.fromMillisecondsSinceEpoch(data['timestamp']);
      if (DateTime.now().difference(timestamp) > _cacheExpiration) {
        return null;
      }
      final boundsData = data['bounds'];
      final southwest = boundsData['southwest'];
      final northeast = boundsData['northeast'];
      return DirectionsResult(
        encodedPolyline: data['encodedPolyline'],
        bounds: LatLngBounds(
          southwest: LatLng(southwest['lat'], southwest['lng']),
          northeast: LatLng(northeast['lat'], northeast['lng']),
        ),
      );
    } catch (e) {
      return null;
    }
  }
  Future<void> clearCache() async {
    _memoryCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('cache_') || key.startsWith('directions_'));
      for (var key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
    }
  }
  Future<void> clearCacheEntry(String key) async {
    _memoryCache.remove(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cache_$key');
      await prefs.remove('directions_$key');
    } catch (e) {
    }
  }
  void dispose() {
    _client.close();
  }
}