import 'dart:convert';
import 'package:dwaya_app/models/pharmacy.dart'; // Adjust if model changes
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dwaya_app/models/directions_result.dart';

// REMOVED: const String _apiKey = "...";

class PlacesService {
  // REMOVED: No longer need API key in the frontend service
  // final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  /// Fetches nearby pharmacies by calling a backend proxy.
  ///
  /// Requires user's current [location] and a [radius] in meters.
  Future<List<Pharmacy>> fetchNearbyPharmacies(
    LatLng location, {
    int radius = 5000,
  }) async {
    // REMOVED: API Key check no longer needed here
    // if (_apiKey.isEmpty) {
    //   print('Error: GOOGLE_MAPS_API_KEY not found in .env file.');
    //   throw Exception('API key not configured.');
    // }

    // Define the URL for your backend proxy endpoint
    // TODO: Replace 'YOUR_PROXY_ENDPOINT_HERE' with your actual proxy URL
    const String proxyBaseUrl = String.fromEnvironment(
      'PROXY_BASE_URL',
      defaultValue:
          'https://workers-playground-round-sea-78ec.hduvehjdvuzv.workers.dev', // Updated with Apps Script URL
    );
    final url = Uri.parse(
      proxyBaseUrl,
    ); // Use the base URL directly as it includes the path

    try {
      // Send data to the proxy via POST request
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'latitude': location.latitude,
          'longitude': location.longitude,
          'radius': radius,
        }),
      );

      if (response.statusCode == 200) {
        // Decode response body explicitly as UTF-8
        final responseBody = utf8.decode(response.bodyBytes);
        final data = json.decode(responseBody);

        // Assuming the proxy returns data in a 'results' list
        // Adjust this based on your actual proxy response structure
        if (data['results'] != null && data['results'] is List) {
          final List results = data['results'];

          // Map proxy results to Pharmacy objects
          // TODO: Verify and adjust this mapping based on the proxy response format
          return results.map((place) {
            // Ensure 'place' is treated as a Map
            final placeData = place as Map<String, dynamic>; 

            // Helper function to safely convert num? to double?
            double? _parseDouble(dynamic value) {
              if (value is num) {
                return value.toDouble();
              }
              return null;
            }

            // Basic fields (handle potential nulls)
            final lat = _parseDouble(placeData['latitude']);
            final lng = _parseDouble(placeData['longitude']);
            final isOpenNow = placeData['isOpen'] as bool? ?? false;
            final imageUrlFromProxy = placeData['imageUrl'] as String? ?? '';

            // New fields from worker (handle potential nulls)
            final rating = _parseDouble(placeData['rating']); // Use helper function
            final userRatingsTotal = placeData['userRatingsTotal'] as int?;
            final phoneNumber = placeData['phoneNumber'] as String?;
            final website = placeData['website'] as String?;
            // openingHours parsing might need adjustment based on how worker sends it
            // Assuming it's sent as a List<String>? or null
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
              isOpen: isOpenNow, // Already defaulted above
              imageUrl: imageUrlFromProxy,
              // Assign new fields
              rating: rating,
              userRatingsTotal: userRatingsTotal,
              phoneNumber: phoneNumber,
              website: website,
              openingHours: openingHours,
            );
          }).toList();
        } else {
          // Handle potential errors reported by the proxy
          final errorMessage = data['error'] ?? 'Unknown error from proxy';
          // print('Proxy Error: $errorMessage'); // Comment
          throw Exception('Proxy Error: $errorMessage');
        }
      } else {
        throw Exception(
          'Failed to load pharmacies from proxy: ${response.statusCode}',
        );
      }
    } catch (e) {
      // print('Error fetching pharmacies via proxy: $e'); // Comment
      // Consider more specific error handling (e.g., network errors)
      throw Exception('Failed to fetch pharmacies via proxy: $e');
    }
  }

  // Fetches directions between two points via the backend proxy.
  Future<DirectionsResult?> getDirections(
    LatLng origin,
    LatLng destination,
  ) async {
    // Use the same base URL but add the /directions path
    const String proxyBaseUrl = String.fromEnvironment(
      'PROXY_BASE_URL',
      defaultValue:
          'https://workers-playground-round-sea-78ec.hduvehjdvuzv.workers.dev',
    );
    final url = Uri.parse('$proxyBaseUrl/directions'); // Append /directions

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'originLat': origin.latitude,
          'originLng': origin.longitude,
          'destinationLat': destination.latitude,
          'destinationLng': destination.longitude,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = json.decode(responseBody);

        // Check for expected data from the worker
        if (data['polyline_encoded'] != null && data['bounds'] != null) {
          final boundsData = data['bounds'];
          final northeast = boundsData['northeast'];
          final southwest = boundsData['southwest'];

          // Basic validation of bounds data
          if (northeast != null && southwest != null && 
              northeast['lat'] != null && northeast['lng'] != null && 
              southwest['lat'] != null && southwest['lng'] != null) {
            
            final bounds = LatLngBounds(
              southwest: LatLng(southwest['lat'], southwest['lng']),
              northeast: LatLng(northeast['lat'], northeast['lng']),
            );

            return DirectionsResult(
              encodedPolyline: data['polyline_encoded'],
              bounds: bounds,
            );
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
      // print('Error fetching directions via proxy: $e'); 
      // Return null or rethrow a more specific exception
      // Depending on how the calling code should handle errors
      // For now, let's rethrow to make errors visible
      throw Exception('Failed to get directions: $e'); 
    }
  }

  // TODO: Add method to fetch place details (for address, photos, etc.) using place_id if needed
  // This might also need to go through the proxy
  // Future<PlaceDetails> fetchPlaceDetails(String placeId) async { ... }
}
