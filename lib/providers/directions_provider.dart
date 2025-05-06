import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dwaya_app/services/places_service.dart';
import 'package:dwaya_app/models/directions_result.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class DirectionsProvider with ChangeNotifier {
  final PlacesService _placesService = PlacesService();

  DirectionsResult? _currentRoute;
  bool _isLoading = false;
  String? _errorMessage;
  Set<Polyline> _polylines = {}; // Store the visual polyline for the map

  DirectionsResult? get currentRoute => _currentRoute;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Set<Polyline> get polylines => _polylines;

  Future<void> findDirections(LatLng origin, LatLng destination) async {
    _isLoading = true;
    _errorMessage = null;
    _currentRoute = null; // Clear previous route
    _polylines = {}; // Clear previous polylines
    notifyListeners();

    try {
      final result = await _placesService.getDirections(origin, destination);
      if (result != null) {
        _currentRoute = result;
        _decodeAndSetPolyline(result.encodedPolyline);
      } else {
        // Handle case where service returns null (though currently it throws)
        _errorMessage = 'Could not retrieve directions data.';
      }
    } catch (e) {
      _errorMessage = 'Error finding directions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _decodeAndSetPolyline(String encodedPolyline) {
     final polylinePoints = PolylinePoints();
     List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(encodedPolyline);
     
     if (decodedPoints.isNotEmpty) {
        final List<LatLng> routePoints = decodedPoints.map((point) {
          return LatLng(point.latitude, point.longitude);
        }).toList();

        final polyline = Polyline(
           polylineId: const PolylineId('route'), // Unique ID for the route polyline
           color: Colors.blueAccent, // Customize color
           width: 5, // Customize width
           points: routePoints,
        );
        _polylines = {polyline}; // Replace current polylines with the new one
     } else {
        _polylines = {}; // Clear if decoding fails
        _errorMessage = "Failed to decode route path."; // Add error message
     }
     // NotifyListeners is called in the finally block of findDirections
  }

  void clearDirections() {
    _currentRoute = null;
    _polylines = {};
    _errorMessage = null;
    notifyListeners();
  }
} 