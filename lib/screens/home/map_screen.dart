import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dwaya_app/utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:dwaya_app/providers/location_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dwaya_app/providers/pharmacy_provider.dart';
import 'dart:async';
import 'package:dwaya_app/providers/app_navigation_provider.dart';
import 'package:dwaya_app/providers/directions_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dwaya_app/models/pharmacy.dart';
const double MIN_RECALCULATION_DISTANCE = 50.0;
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => MapScreenState();
}
class MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Pharmacy> _filteredPharmacies = [];
  Timer? _debounce;
  bool _showSearchResults = false;
  Set<Marker> _markers = {};
  LatLng? _lastFocusedLocation;
  bool _isNavigating = false;
  LatLng? _navigationDestination;
  Position? _lastRouteCalculationPosition;
  Pharmacy? _selectedPharmacyForNavigation;
  void _clearPharmacySelection() {
    if (_selectedPharmacyForNavigation != null && !_isNavigating) {
      setState(() {
        _selectedPharmacyForNavigation = null;
        final pharmacyProvider = context.read<PharmacyProvider>();
        _updateMarkers(pharmacyProvider.pharmacies);
      });
    }
  }
  static const CameraPosition _kDefaultPosition = CameraPosition(
    target: LatLng(40.7128, -74.0060),
    zoom: 12,
  );
  @override
  void initState() {
    super.initState();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pharmacyProvider = context.read<PharmacyProvider>();
    if (!_isNavigating && _selectedPharmacyForNavigation == null) {
      _updateMarkers(pharmacyProvider.pharmacies);
    }
    _handleMapFocusRequest();
    _handleDirectionsResult();
    final locationProvider = context.watch<LocationProvider>();
    if (_isNavigating && locationProvider.currentPosition != null) {
      if (_lastRouteCalculationPosition == null ||
          (locationProvider.currentPosition!.latitude != _lastRouteCalculationPosition!.latitude ||
           locationProvider.currentPosition!.longitude != _lastRouteCalculationPosition!.longitude)) {
        _onLocationUpdate(locationProvider.currentPosition!);
      }
    }
  }
  void _handleMapFocusRequest() {
    final navProvider = context.watch<AppNavigationProvider>();
    final targetPharmacy = navProvider.targetPharmacyForMapFocus;
    if (navProvider.shouldAnimateMap() && targetPharmacy != null &&
        (targetPharmacy.latitude != null && targetPharmacy.longitude != null)) {
      final targetLocation = LatLng(targetPharmacy.latitude!, targetPharmacy.longitude!);
      if ((_selectedPharmacyForNavigation?.id == targetPharmacy.id && _selectedPharmacyForNavigation != null) ||
          (_lastFocusedLocation?.latitude == targetLocation.latitude &&
           _lastFocusedLocation?.longitude == targetLocation.longitude)) {
        if(!navProvider.shouldAnimateMap()){
            context.read<AppNavigationProvider>().clearMapFocus();
        }
        return;
      }
      _lastFocusedLocation = targetLocation;
      if (_isNavigating && (_navigationDestination != targetLocation)) {
        _stopNavigation();
      }
      setState(() {
        _selectedPharmacyForNavigation = targetPharmacy;
        _markers = {
          Marker(
            markerId: MarkerId(targetPharmacy.id),
            position: targetLocation,
            infoWindow: InfoWindow(title: targetPharmacy.name, snippet: targetPharmacy.isOpen ? 'Open' : 'Closed'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          )
        };
      });
      if (_mapController != null) {
         _mapController!.showMarkerInfoWindow(MarkerId(targetPharmacy.id));
      } else {
        _controller.future.then((controller) {
            controller.showMarkerInfoWindow(MarkerId(targetPharmacy.id));
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _animateToLocation(targetLocation);
          context.read<AppNavigationProvider>().clearMapFocus();
        }
      });
    } else if (!navProvider.shouldAnimateMap() && targetPharmacy != null) {
      context.read<AppNavigationProvider>().clearMapFocus();
    }
  }
  void _handleDirectionsResult() {
    final directionsProvider = context.watch<DirectionsProvider>();
    final route = directionsProvider.currentRoute;
    if (route != null && directionsProvider.polylines.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _mapController != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLngBounds(route.bounds, 50.0));
        }
      });
    }
  }
  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _stopNavigation();
    super.dispose();
  }
  void _handleMapSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final trimmedQuery = query.trim();
      setState(() {
        _searchQuery = trimmedQuery;
        if (trimmedQuery.isEmpty) {
          _filteredPharmacies = [];
          _showSearchResults = false;
        } else {
          final pharmacyProvider = context.read<PharmacyProvider>();
          _filteredPharmacies = pharmacyProvider.pharmacies.where((pharmacy) {
            return pharmacy.name.toLowerCase().contains(trimmedQuery.toLowerCase());
          }).toList();
          _showSearchResults = true;
        }
      });
    });
  }
  void _clearSearchAndDirections() {
    _searchController.clear();
    _stopNavigation();
    setState(() {
      _searchQuery = '';
      _filteredPharmacies = [];
      _showSearchResults = false;
    });
    FocusScope.of(context).unfocus();
  }
  Future<void> _goToPharmacy(Pharmacy pharmacy) async {
    if (pharmacy.latitude == null || pharmacy.longitude == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location coordinates not available for ${pharmacy.name}.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }
    if (_isNavigating) {
      _stopNavigation();
    }
    setState(() {
      _selectedPharmacyForNavigation = pharmacy;
    });
    final LatLng pharmacyLocation = LatLng(pharmacy.latitude!, pharmacy.longitude!);
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: pharmacyLocation,
        zoom: 16.0,
      ),
    ));
    final selectedMarker = Marker(
      markerId: MarkerId(pharmacy.id),
      position: pharmacyLocation,
      infoWindow: InfoWindow(
        title: pharmacy.name,
        snippet: pharmacy.isOpen ? 'Open' : 'Closed',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    );
    setState(() {
      _markers = {selectedMarker};
      _searchController.clear();
      _searchQuery = '';
      _filteredPharmacies = [];
      _showSearchResults = false;
    });
    _mapController?.showMarkerInfoWindow(MarkerId(pharmacy.id));
    FocusScope.of(context).unfocus();
  }
  Future<void> _animateToLocation(LatLng location) async {
    final GoogleMapController controller = _mapController ?? await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: location,
        zoom: 16.0,
      ),
    ));
  }
  void _updateMarkers(List<Pharmacy> pharmacies) {
    if (!mounted) return;
    final Set<Marker> newMarkers = pharmacies.where((p) => p.latitude != null && p.longitude != null).map((pharmacy) {
      return Marker(
        markerId: MarkerId(pharmacy.id),
        position: LatLng(pharmacy.latitude!, pharmacy.longitude!),
        infoWindow: InfoWindow(title: pharmacy.name, snippet: pharmacy.isOpen ? 'Open' : 'Closed'),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          (_selectedPharmacyForNavigation?.id == pharmacy.id)
              ? BitmapDescriptor.hueYellow
              : (pharmacy.isOpen ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed),
        ),
        onTap: () {
          if (_isNavigating) {
            _stopNavigation();
          }
          setState(() {
            _selectedPharmacyForNavigation = pharmacy;
            _markers = {
              Marker(
                markerId: MarkerId(pharmacy.id),
                position: LatLng(pharmacy.latitude!, pharmacy.longitude!),
                infoWindow: InfoWindow(title: pharmacy.name, snippet: pharmacy.isOpen ? 'Open' : 'Closed'),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
              )
            };
          });
          _mapController?.showMarkerInfoWindow(MarkerId(pharmacy.id));
        },
      );
    }).toSet();
    if (_selectedPharmacyForNavigation == null || _markers.length != 1) {
        setState(() {
          _markers = newMarkers;
        });
    }
  }
  CameraPosition _getInitialCameraPosition(LocationProvider locationProvider) {
    final userPosition = locationProvider.currentPosition;
    if (userPosition != null) {
      return CameraPosition(
        target: LatLng(userPosition.latitude, userPosition.longitude),
        zoom: 14.4746,
      );
    } else {
      return _kDefaultPosition;
    }
  }
  Future<void> _startOrUpdateNavigation(LatLng destination) async {
    final locationProvider = context.read<LocationProvider>();
    if (locationProvider.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Current location not available to start navigation.")),
      );
      return;
    }
    setState(() {
      _isNavigating = true;
      _navigationDestination = destination;
      _lastRouteCalculationPosition = locationProvider.currentPosition;
      _selectedPharmacyForNavigation = null;
    });
    await locationProvider.startLocationUpdates();
    final directionsProvider = context.read<DirectionsProvider>();
    await directionsProvider.findDirections(
        LatLng(locationProvider.currentPosition!.latitude, locationProvider.currentPosition!.longitude),
        destination);
    if (_mapController != null && locationProvider.currentPosition != null) {
         _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
                LatLng(locationProvider.currentPosition!.latitude, locationProvider.currentPosition!.longitude),
                16.0
            )
        );
    }
  }
  void _onLocationUpdate(Position newPosition) {
    if (!_isNavigating || _navigationDestination == null || _lastRouteCalculationPosition == null) {
      return;
    }
    final double distance = Geolocator.distanceBetween(
      _lastRouteCalculationPosition!.latitude,
      _lastRouteCalculationPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );
    if (distance > MIN_RECALCULATION_DISTANCE) {
      setState(() {
        _lastRouteCalculationPosition = newPosition;
      });
      final directionsProvider = context.read<DirectionsProvider>();
      directionsProvider.findDirections(
          LatLng(newPosition.latitude, newPosition.longitude),
          _navigationDestination!);
    } else {
    }
  }
  void _stopNavigation() {
    if (!_isNavigating && _navigationDestination == null && _selectedPharmacyForNavigation == null) return;
    setState(() {
      _isNavigating = false;
      _navigationDestination = null;
      _lastRouteCalculationPosition = null;
      _selectedPharmacyForNavigation = null;
    });
    if (mounted) {
        context.read<LocationProvider>().stopLocationUpdates();
        context.read<DirectionsProvider>().clearDirections();
    }
    final pharmacyProvider = context.read<PharmacyProvider>();
    _updateMarkers(pharmacyProvider.pharmacies);
  }
  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final directionsProvider = context.watch<DirectionsProvider>();
    double currentBottomPadding = 0.0;
    if (_isNavigating) {
      currentBottomPadding = 60.0;
    } else if (_selectedPharmacyForNavigation != null) {
      currentBottomPadding = 80.0;
    }
    return Scaffold(
      floatingActionButton: _isNavigating
          ? FloatingActionButton.extended(
              onPressed: _stopNavigation,
              label: const Text('Stop Navigation'),
              icon: const Icon(Icons.close),
              backgroundColor: Colors.redAccent,
              heroTag: 'fabStopNavigation',
            )
          : _selectedPharmacyForNavigation != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton.extended(
                      onPressed: () {
                        if (_selectedPharmacyForNavigation!.latitude != null &&
                            _selectedPharmacyForNavigation!.longitude != null) {
                          _startOrUpdateNavigation(LatLng(
                            _selectedPharmacyForNavigation!.latitude!,
                            _selectedPharmacyForNavigation!.longitude!,
                          ));
                        }
                      },
                      label: const Text('Get Directions'),
                      icon: const Icon(Icons.directions),
                      backgroundColor: primaryGreen,
                      heroTag: 'fabDirections',
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton.extended(
                      onPressed: _clearPharmacySelection,
                      label: const Text('Cancel'),
                      icon: const Icon(Icons.cancel_outlined),
                      backgroundColor: Colors.grey,
                      heroTag: 'fabCancelSelection',
                    ),
                  ],
                )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Stack(
        children: [
          if (!locationProvider.isLoadingLocation)
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _getInitialCameraPosition(
                locationProvider,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                }
              },
              markers: _markers,
              polylines: directionsProvider.polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onTap: (_) {
                _clearPharmacySelection();
              },
              padding: EdgeInsets.only(
                top: 100.0,
                bottom: currentBottomPadding,
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: primaryGreen)),
          if (directionsProvider.isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ),
          if (directionsProvider.errorMessage != null)
            Positioned(
              bottom: 20,
              left: 15,
              right: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        directionsProvider.errorMessage!,
                        style: const TextStyle(color: white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => directionsProvider.clearDirections(),
                    )
                  ],
                ),
              ),
            ),
          Positioned(
            top: 50,
            left: 15,
            right: 15,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(30.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search pharmacies by name...',
                  border: InputBorder.none,
                      icon: const Icon(Icons.search, color: darkGrey),
                      suffixIcon: _searchQuery.isNotEmpty || directionsProvider.polylines.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: darkGrey),
                              onPressed: _clearSearchAndDirections,
                            )
                          : null,
                    ),
                    onChanged: _handleMapSearchChanged,
                  ),
                ),
                if (_showSearchResults)
                  Container(
                    margin: const EdgeInsets.only(top: 4.0),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.3,
                    ),
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.circular(15.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _filteredPharmacies.isNotEmpty
                        ? ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: _filteredPharmacies.length,
                            itemBuilder: (context, index) {
                              final pharmacy = _filteredPharmacies[index];
                              return ListTile(
                                title: Text(pharmacy.name),
                                subtitle: Text(pharmacy.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                                dense: true,
                                onTap: () => _goToPharmacy(pharmacy),
                              );
                            },
                          )
                        : const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No pharmacies found matching the name.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
              ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}