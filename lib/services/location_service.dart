import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();
  Position? _lastKnownPosition;
  DateTime? _lastPositionTimestamp;
  StreamController<Position>? _positionStreamController;
  StreamSubscription<Position>? _geolocatorStreamSubscription;
  Future<bool> requestLocationPermission() async {
    try {
      PermissionStatus status = await Permission.locationWhenInUse.status;
      if (status.isGranted) {
        return true;
      }
      status = await Permission.locationWhenInUse.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }
  Future<Position?> getCurrentLocation({bool highAccuracy = true, bool useCachedLocation = true}) async {
    if (useCachedLocation && _lastKnownPosition != null && _lastPositionTimestamp != null) {
      final now = DateTime.now();
      final timeSinceLastPosition = now.difference(_lastPositionTimestamp!);
      if (timeSinceLastPosition.inSeconds < 30) {
        return _lastKnownPosition;
      }
    }
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return null;
      }
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestedPermission = await Geolocator.requestPermission();
        if (requestedPermission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied');
        return null;
      }
      final desiredAccuracy = _determineLocationAccuracy(highAccuracy);
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: desiredAccuracy,
        timeLimit: const Duration(seconds: 15),
      );
      _lastKnownPosition = position;
      _lastPositionTimestamp = DateTime.now();
      return position;
    } on TimeoutException {
      debugPrint('Location request timed out');
      return _lastKnownPosition;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }
  Stream<Position> getPositionStream([LocationSettings? settings]) {
    _disposePositionStream();
    _positionStreamController = StreamController<Position>.broadcast();
    final locationSettings = settings ?? _getDefaultLocationSettings();
    _geolocatorStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) {
        _lastKnownPosition = position;
        _lastPositionTimestamp = DateTime.now();
        if (_positionStreamController != null && !_positionStreamController!.isClosed) {
          _positionStreamController!.add(position);
        }
      },
      onError: (error) {
        debugPrint('Error in location stream: $error');
        if (_positionStreamController != null && !_positionStreamController!.isClosed) {
          _positionStreamController!.addError(error);
        }
      },
      cancelOnError: false,
    );
    return _positionStreamController!.stream;
  }
  LocationAccuracy _determineLocationAccuracy(bool highAccuracy) {
    if (kIsWeb) {
      return LocationAccuracy.reduced;
    } else if (!highAccuracy) {
      return LocationAccuracy.reduced;
    } else {
      return LocationAccuracy.high;
    }
  }
  LocationSettings _getDefaultLocationSettings() {
    if (kIsWeb) {
      return const LocationSettings(
        accuracy: LocationAccuracy.reduced,
        distanceFilter: 100,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
  }
  void _disposePositionStream() {
    _geolocatorStreamSubscription?.cancel();
    _geolocatorStreamSubscription = null;
    _positionStreamController?.close();
    _positionStreamController = null;
  }
  void clearCache() {
    _lastKnownPosition = null;
    _lastPositionTimestamp = null;
  }
  void dispose() {
    _disposePositionStream();
    clearCache();
  }
}