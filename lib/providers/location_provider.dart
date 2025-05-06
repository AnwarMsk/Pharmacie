import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dwaya_app/services/location_service.dart';
import 'dart:async'; // Import for StreamSubscription

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();

  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
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

  Future<void> startLocationUpdates() async {
    // Ensure permissions are checked and service is enabled before starting
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _errorMessage = "Location services are disabled.";
      _locationServiceInitiallyDisabled = true; // Reflect state
      notifyListeners();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _errorMessage = "Location permission denied.";
      _locationPermissionDenied = true; // Reflect state
      notifyListeners();
      // Optionally, could try to request permission here or guide user
      return;
    }

    await _positionStreamSubscription?.cancel(); // Cancel any existing subscription
    _positionStreamSubscription = _locationService.getPositionStream().listen(
      (Position position) {
        _currentPosition = position;
        _isLoadingLocation = false; // No longer loading initial, now updating
        _errorMessage = null; // Clear previous errors if any
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = "Error getting location updates: $error";
        // Potentially stop updates or set a flag indicating stream failure
        notifyListeners();
      },
      onDone: () {
        // Stream closed, perhaps set a flag or log
        // _isLoadingLocation = true; // Or some other state if stream unexpectedly closes
        // notifyListeners();
      },
      cancelOnError: false, // Keep listening even if one error occurs, or set to true to stop
    );
    // Indicate that we are actively listening (if a new flag is desired)
    // _isListeningToUpdates = true;
    // notifyListeners();
  }

  void stopLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    // Indicate that we are no longer listening (if a flag is used)
    // _isListeningToUpdates = false;
    // notifyListeners();
  }

  @override
  void dispose() {
    stopLocationUpdates();
    super.dispose();
  }
}
