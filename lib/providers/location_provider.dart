import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dwaya_app/services/location_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();

  Position? _currentPosition;
  bool _isLoadingLocation = true;
  bool _locationServiceInitiallyDisabled = false;
  bool _locationPermissionDenied = false;
  String? _errorMessage;

  Position? get currentPosition => _currentPosition;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get locationServiceInitiallyDisabled =>
      _locationServiceInitiallyDisabled;
  bool get locationPermissionDenied => _locationPermissionDenied;
  String? get errorMessage => _errorMessage;

  LocationProvider() {
    // Fetch location when the provider is first created
    fetchInitialLocation();
  }

  Future<void> fetchInitialLocation({bool forceDialog = false}) async {
    // Reset flags unless forced
    if (!forceDialog) {
      _locationServiceInitiallyDisabled = false;
      _locationPermissionDenied = false;
      _errorMessage = null;
    }
    _isLoadingLocation = true;
    notifyListeners();

    try {
      // Clear previous errors/states before attempting
    _currentPosition = await _locationService.getCurrentLocation();

    if (_currentPosition == null) {
      // Check status to set flags
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationServiceInitiallyDisabled = true;
      } else {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _locationPermissionDenied = true;
        }
      }
    } else {

    }

    _isLoadingLocation = false;
    notifyListeners();
    } catch (e) {
      _errorMessage = "Failed to get location: $e";
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  // Add methods to request permission or open settings if needed
  Future<bool> requestPermission() async {
    bool granted = await _locationService.requestLocationPermission();
    if (granted) {
      await fetchInitialLocation(); // Refetch on grant
    }
    notifyListeners();
    return granted;
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
    // Optionally refetch after return, though user might not have enabled it yet
  }
}
