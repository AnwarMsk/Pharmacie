import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Requests location permission (when in use).
  /// Returns true if permission is granted, false otherwise.
  Future<bool> requestLocationPermission() async {
    PermissionStatus status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  /// Gets the current device location.
  /// Returns Position if successful and permission granted.
  /// Throws an exception or returns null if service disabled, permission denied, or error occurs.
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    final status = await Geolocator.checkPermission();

    LocationPermission permission;

    if (status == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      // We call requestPermission again here just in case the previous `requestLocationPermission`
      // failed silently, although ideally the check should happen before calling this method.
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (status == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      // Consider calling openAppSettings() here if needed, after informing user.
      return null;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      return await Geolocator.getCurrentPosition(
        // Desired accuracy can be adjusted
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  /// Returns a stream of position updates.
  Stream<Position> getPositionStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );
    // Special settings for web to ensure it continues to poll
    // const LocationSettings webLocationSettings = LocationSettings(
    //   accuracy: LocationAccuracy.high,
    //   distanceFilter: 100, // Or appropriate value
    //   // timeLimit: Duration(seconds: 10), // Example: force update every 10s on web if no movement
    // );

    // if (kIsWeb) {
    //   return Geolocator.getPositionStream(locationSettings: webLocationSettings);
    // } else {
    return Geolocator.getPositionStream(locationSettings: locationSettings);
    // }
  }
}
