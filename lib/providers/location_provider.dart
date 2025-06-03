import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dwaya_app/services/location_service.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  networkError,
  timeout,
  unknown
}
class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isLoadingLocation = true;
  bool _locationServiceInitiallyDisabled = false;
  bool _locationPermissionDenied = false;
  String? _errorMessage;
  LocationErrorType? _errorType;
  bool _isActive = true;
  DateTime? _lastLocationUpdate;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  Position? get currentPosition => _currentPosition;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get locationServiceInitiallyDisabled => _locationServiceInitiallyDisabled;
  bool get locationPermissionDenied => _locationPermissionDenied;
  String? get errorMessage => _errorMessage;
  LocationErrorType? get errorType => _errorType;
  DateTime? get lastLocationUpdate => _lastLocationUpdate;
  bool get hasValidLocation => _currentPosition != null &&
      (_lastLocationUpdate != null &&
       DateTime.now().difference(_lastLocationUpdate!) < const Duration(minutes: 5));
  LocationProvider() {
    fetchInitialLocation();
  }
  Future<void> fetchInitialLocation({bool forceDialog = false}) async {
    if (!_isActive) return;
    if (!forceDialog) {
      _locationServiceInitiallyDisabled = false;
      _locationPermissionDenied = false;
      _errorMessage = null;
      _errorType = null;
      _retryCount = 0;
    }
    _isLoadingLocation = true;
    notifyListeners();
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError(
          "Location services are disabled. Please enable location services in device settings.",
          LocationErrorType.serviceDisabled
        );
        _locationServiceInitiallyDisabled = true;
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError(
            "Location permission denied. The app needs location access to find nearby pharmacies.",
            LocationErrorType.permissionDenied
          );
          _locationPermissionDenied = true;
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _setError(
          "Location permissions are permanently denied. Please enable in device settings.",
          LocationErrorType.permissionDeniedForever
        );
        _locationPermissionDenied = true;
        return;
      }
      _currentPosition = await _locationService.getCurrentLocation()
          .timeout(const Duration(seconds: 15), onTimeout: () {
        _setError(
          "Location request timed out. Please try again.",
          LocationErrorType.timeout
        );
        return null;
      });
      if (_currentPosition == null) {
        _setError(
          "Couldn't determine your location. Please check your GPS signal and try again.",
          LocationErrorType.unknown
        );
      } else {
        _lastLocationUpdate = DateTime.now();
        _errorMessage = null;
        _errorType = null;
      }
    } on TimeoutException {
      _setError(
        "Location request timed out. Please try again.",
        LocationErrorType.timeout
      );
    } catch (e) {
      _setError(
        "Failed to get location: $e",
        LocationErrorType.unknown
      );
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }
  void _setError(String message, LocationErrorType type) {
    _errorMessage = message;
    _errorType = type;
    _isLoadingLocation = false;
  }
  Future<bool> requestPermission() async {
    try {
      bool granted = await _locationService.requestLocationPermission();
      if (granted) {
        _locationPermissionDenied = false;
        _errorType = null;
        _errorMessage = null;
        await fetchInitialLocation();
      } else {
        _locationPermissionDenied = true;
        _setError(
          "Location permission denied. The app needs location access to find nearby pharmacies.",
          LocationErrorType.permissionDenied
        );
      }
      notifyListeners();
      return granted;
    } catch (e) {
      _setError(
        "Failed to request permission: $e",
        LocationErrorType.unknown
      );
      notifyListeners();
      return false;
    }
  }
  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      _setError(
        "Failed to open location settings: $e",
        LocationErrorType.unknown
      );
      notifyListeners();
    }
  }
  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      _setError(
        "Failed to open app settings: $e",
        LocationErrorType.unknown
      );
      notifyListeners();
    }
  }
  Future<void> startLocationUpdates({bool highAccuracy = false}) async {
    _isActive = true;
    if (_lastLocationUpdate != null) {
      final timeSinceLastUpdate = DateTime.now().difference(_lastLocationUpdate!);
      if (timeSinceLastUpdate < const Duration(minutes: 2)) {
        return;
      }
    }
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError(
          "Location services are disabled.",
          LocationErrorType.serviceDisabled
        );
        _locationServiceInitiallyDisabled = true;
        notifyListeners();
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        _setError(
          "Location permission denied.",
          LocationErrorType.permissionDenied
        );
        _locationPermissionDenied = true;
        notifyListeners();
        return;
      } else if (permission == LocationPermission.deniedForever) {
        _setError(
          "Location permissions are permanently denied. Please enable in device settings.",
          LocationErrorType.permissionDeniedForever
        );
        _locationPermissionDenied = true;
        notifyListeners();
        return;
      }
      await _positionStreamSubscription?.cancel();
      final locationSettings = LocationSettings(
        accuracy: highAccuracy ? LocationAccuracy.high : LocationAccuracy.reduced,
        distanceFilter: highAccuracy ? 10 : 50,
        timeLimit: const Duration(seconds: 30),
      );
      _positionStreamSubscription = _locationService.getPositionStream(locationSettings).listen(
        (Position position) {
          _currentPosition = position;
          _isLoadingLocation = false;
          _errorMessage = null;
          _errorType = null;
          _lastLocationUpdate = DateTime.now();
          _retryCount = 0;
          notifyListeners();
        },
        onError: (error) {
          if (error is LocationServiceDisabledException) {
            _setError(
              "Location services disabled during updates. Please enable location services.",
              LocationErrorType.serviceDisabled
            );
            _locationServiceInitiallyDisabled = true;
          } else if (error is PermissionDeniedException) {
            _setError(
              "Location permission denied during updates.",
              LocationErrorType.permissionDenied
            );
            _locationPermissionDenied = true;
          } else if (error is TimeoutException) {
            _setError(
              "Location update timed out.",
              LocationErrorType.timeout
            );
            _tryRetry();
          } else {
            _setError(
              "Error getting location updates: $error",
              LocationErrorType.unknown
            );
            _tryRetry();
          }
          notifyListeners();
        },
        cancelOnError: false,
      );
    } catch (e) {
      _setError(
        "Failed to start location updates: $e",
        LocationErrorType.unknown
      );
      notifyListeners();
    }
  }
  void _tryRetry() {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      Future.delayed(Duration(seconds: 5 * _retryCount), () {
        if (_isActive) {
          startLocationUpdates();
        }
      });
    }
  }
  Future<bool> ensureLocationAvailable({bool highAccuracy = false}) async {
    if (hasValidLocation) return true;
    if (_isLoadingLocation) return false;
    _isLoadingLocation = true;
    notifyListeners();
    try {
      await fetchInitialLocation();
      if (_currentPosition != null) {
        return true;
      }
      if (_locationServiceInitiallyDisabled || _locationPermissionDenied) {
        return false;
      }
      _currentPosition = await _locationService.getCurrentLocation(highAccuracy: true)
          .timeout(const Duration(seconds: 15));
      if (_currentPosition != null) {
        _lastLocationUpdate = DateTime.now();
        _errorMessage = null;
        _errorType = null;
        _isLoadingLocation = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError(
        "Failed to get location: $e",
        LocationErrorType.unknown
      );
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
    return false;
  }
  void pauseLocationUpdates() {
    _isActive = false;
    stopLocationUpdates();
  }
  void resumeLocationUpdates({bool highAccuracy = false}) {
    _isActive = true;
    startLocationUpdates(highAccuracy: highAccuracy);
  }
  void stopLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
  @override
  void dispose() {
    stopLocationUpdates();
    super.dispose();
  }
}