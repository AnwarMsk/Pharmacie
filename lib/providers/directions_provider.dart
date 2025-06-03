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
  Set<Polyline> _polylines = {};
  DirectionsResult? get currentRoute => _currentRoute;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Set<Polyline> get polylines => _polylines;
  Future<void> findDirections(LatLng origin, LatLng destination) async {
    _isLoading = true;
    _errorMessage = null;
    _currentRoute = null;
    _polylines = {};
    notifyListeners();
    try {
      final result = await _placesService.getDirections(origin, destination);
      if (result != null) {
        _currentRoute = result;
        _decodeAndSetPolyline(result.encodedPolyline);
      } else {
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
           polylineId: const PolylineId('route'),
           color: Colors.blueAccent,
           width: 5,
           points: routePoints,
        );
        _polylines = {polyline};
     } else {
        _polylines = {};
        _errorMessage = "Failed to decode route path.";
     }
  }
  void clearDirections() {
    _currentRoute = null;
    _polylines = {};
    _errorMessage = null;
    notifyListeners();
  }
}