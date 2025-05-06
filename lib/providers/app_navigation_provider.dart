import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dwaya_app/models/pharmacy.dart'; // Import Pharmacy model

class AppNavigationProvider with ChangeNotifier {
  int _currentTabIndex = 0;
  Pharmacy? _targetPharmacyForMapFocus; // New: store the whole pharmacy object
  bool _navigationRequestPending = false;

  int get currentTabIndex => _currentTabIndex;
  Pharmacy? get targetPharmacyForMapFocus => _targetPharmacyForMapFocus; // New getter

  // Called when a bottom navigation tab is tapped
  void navigateToTab(int index) {
    if (_currentTabIndex == index) return; // No change
    _currentTabIndex = index;
    _targetPharmacyForMapFocus = null; // Clear pharmacy focus
    _navigationRequestPending = false; // Clear pending flag
    notifyListeners();
  }

  // Called from detail screen to show location on map tab
  void focusMapOnLocation(LatLng location, {Pharmacy? pharmacy}) {
    if (pharmacy != null) {
      _targetPharmacyForMapFocus = pharmacy;
    } else {
      // Fallback if only LatLng is provided (e.g., from a source not having full pharmacy data)
      // Create a temporary pharmacy object. This is less ideal as name will be missing.
      // Consider making Pharmacy compulsory if always available.
      _targetPharmacyForMapFocus = Pharmacy(
        id: 'temp_focused_location', // Temporary ID
        name: 'Focused Location', // Generic name
        address: 'Coordinates: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
        latitude: location.latitude,
        longitude: location.longitude,
        isOpen: false, // Default, not known
        imageUrl: '', // Provide an empty string for the non-nullable parameter
        // Other fields can be null or default if not available
      );
    }
    _currentTabIndex = 1; // Index of the Map/Search tab
    _navigationRequestPending = true; // Set flag
    notifyListeners();
  }

  // Called by MapScreen after it has processed the focus request
  void clearMapFocus() {
    if (_targetPharmacyForMapFocus != null || _navigationRequestPending) {
      _targetPharmacyForMapFocus = null;
      _navigationRequestPending = false;
      // Don't notify listeners here, as MapScreen handles the UI update (camera animation)
      // and we don't want to trigger rebuilds just for clearing.
    }
  }

  // Called by MapScreen to check if it should animate
  bool shouldAnimateMap() {
    return _navigationRequestPending && _targetPharmacyForMapFocus != null;
  }
} 