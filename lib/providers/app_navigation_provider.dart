import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dwaya_app/models/pharmacy.dart';
class AppNavigationProvider with ChangeNotifier {
  int _currentTabIndex = 0;
  Pharmacy? _targetPharmacyForMapFocus;
  bool _navigationRequestPending = false;
  int get currentTabIndex => _currentTabIndex;
  Pharmacy? get targetPharmacyForMapFocus => _targetPharmacyForMapFocus;
  void navigateToTab(int index) {
    if (_currentTabIndex == index) return;
    _currentTabIndex = index;
    _targetPharmacyForMapFocus = null;
    _navigationRequestPending = false;
    notifyListeners();
  }
  void focusMapOnLocation(LatLng location, {Pharmacy? pharmacy}) {
    if (pharmacy != null) {
      _targetPharmacyForMapFocus = pharmacy;
    } else {
      _targetPharmacyForMapFocus = Pharmacy(
        id: 'temp_focused_location',
        name: 'Focused Location',
        address: 'Coordinates: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
        latitude: location.latitude,
        longitude: location.longitude,
        isOpen: false,
        imageUrl: '',
      );
    }
    _currentTabIndex = 1;
    _navigationRequestPending = true;
    notifyListeners();
  }
  void clearMapFocus() {
    if (_targetPharmacyForMapFocus != null || _navigationRequestPending) {
      _targetPharmacyForMapFocus = null;
      _navigationRequestPending = false;
    }
  }
  bool shouldAnimateMap() {
    return _navigationRequestPending && _targetPharmacyForMapFocus != null;
  }
}