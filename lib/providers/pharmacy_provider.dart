import 'package:dwaya_app/models/pharmacy.dart';
import 'package:dwaya_app/services/places_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class PharmacyProvider with ChangeNotifier {
  final PlacesService _placesService = PlacesService();

  List<Pharmacy> _pharmacies = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Pharmacy> get pharmacies => _pharmacies;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Method to fetch pharmacies based on location
  Future<void> fetchAndSetPharmacies(LatLng location) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch pharmacies (they won't have distance yet)
      List<Pharmacy> fetchedPharmacies = await _placesService.fetchNearbyPharmacies(location);

      // Calculate distances if location is available
      if (location != null) {
        for (var i = 0; i < fetchedPharmacies.length; i++) {
          final pharmacy = fetchedPharmacies[i];
          if (pharmacy.latitude != null && pharmacy.longitude != null) {
            final distanceInMeters = Geolocator.distanceBetween(
              location.latitude,
              location.longitude,
              pharmacy.latitude!,
              pharmacy.longitude!,
            );
            // Create a new Pharmacy instance with the distance and other details
            fetchedPharmacies[i] = Pharmacy(
              id: pharmacy.id,
              name: pharmacy.name,
              address: pharmacy.address,
              isOpen: pharmacy.isOpen,
              imageUrl: pharmacy.imageUrl,
              latitude: pharmacy.latitude,
              longitude: pharmacy.longitude,
              distance: distanceInMeters, // Set the calculated distance
              // Pass through the other fields fetched by PlacesService
              rating: pharmacy.rating,
              userRatingsTotal: pharmacy.userRatingsTotal,
              phoneNumber: pharmacy.phoneNumber,
              website: pharmacy.website,
              openingHours: pharmacy.openingHours,
            );
          } else {
            // If lat/lng is missing, keep the original pharmacy object (no distance)
             // We still need to ensure the other optional fields are preserved
             fetchedPharmacies[i] = Pharmacy(
                id: pharmacy.id,
                name: pharmacy.name,
                address: pharmacy.address,
                isOpen: pharmacy.isOpen,
                imageUrl: pharmacy.imageUrl,
                latitude: pharmacy.latitude,
                longitude: pharmacy.longitude,
                distance: null, // No distance
                rating: pharmacy.rating,
                userRatingsTotal: pharmacy.userRatingsTotal,
                phoneNumber: pharmacy.phoneNumber,
                website: pharmacy.website,
                openingHours: pharmacy.openingHours,
            );
          }
        }
        // Optional: Sort by distance
        fetchedPharmacies.sort((a, b) => (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));
      }

      _pharmacies = fetchedPharmacies; // Assign the list with distances

    } catch (e) {
      _errorMessage = 'Failed to load pharmacies: $e';
      _pharmacies = []; // Clear pharmacies on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Optional: Clear pharmacies
  void clearPharmacies() {
    _pharmacies = [];
    _errorMessage = null;
    notifyListeners();
  }
}
