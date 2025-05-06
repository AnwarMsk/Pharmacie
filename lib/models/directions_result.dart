// lib/models/directions_result.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionsResult {
  final String encodedPolyline;
  final LatLngBounds bounds;

  DirectionsResult({required this.encodedPolyline, required this.bounds});
} 