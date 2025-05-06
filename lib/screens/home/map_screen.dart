import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dwaya_app/utils/colors.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:dwaya_app/providers/location_provider.dart'; // Import LocationProvider
import 'package:url_launcher/url_launcher.dart';
import 'package:dwaya_app/providers/pharmacy_provider.dart'; // Import PharmacyProvider
import 'dart:async'; // Import Timer
import 'package:dwaya_app/providers/app_navigation_provider.dart'; // Import AppNavigationProvider
import 'package:dwaya_app/providers/directions_provider.dart'; // Import DirectionsProvider
import 'package:geolocator/geolocator.dart'; // Import Geolocator for distance calculation

import 'package:dwaya_app/models/pharmacy.dart';

// Define this constant at the class level or outside if preferred
const double MIN_RECALCULATION_DISTANCE = 50.0; // in meters

class MapScreen extends StatefulWidget {
  // Remove userPosition parameter
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  GoogleMapController? _mapController; // Store controller for later use

  // State for pharmacy search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Pharmacy> _filteredPharmacies = [];
  Timer? _debounce;
  bool _showSearchResults = false; // To control visibility of results list

  // Make markers a state variable
  Set<Marker> _markers = {};

  // Keep track of the last focused location to prevent re-animation
  LatLng? _lastFocusedLocation;

  // Navigation state
  bool _isNavigating = false;
  LatLng? _navigationDestination;
  Position? _lastRouteCalculationPosition;
  Pharmacy? _selectedPharmacyForNavigation; // Pharmacy selected, ready for navigation

  // Method to clear the current pharmacy selection and reset markers
  void _clearPharmacySelection() {
    // Only clear if a pharmacy is selected for navigation prep AND actual navigation is not active
    if (_selectedPharmacyForNavigation != null && !_isNavigating) {
      setState(() {
        _selectedPharmacyForNavigation = null;
        // Restore all markers from the provider
        final pharmacyProvider = context.read<PharmacyProvider>();
        _updateMarkers(pharmacyProvider.pharmacies);
        // _lastFocusedLocation = null; // Optionally clear this to allow re-focus via provider if needed
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
    // Potential: Load initial pharmacies here if needed, or rely on home screen load
  }

  // Use didChangeDependencies to safely access providers for initial marker load
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pharmacyProvider = context.read<PharmacyProvider>(); // Read once
    // Update markers with the currently loaded list from PharmacyProvider
    // Only update if not navigating and no specific pharmacy is selected for navigation prep
    if (!_isNavigating && _selectedPharmacyForNavigation == null) {
      _updateMarkers(pharmacyProvider.pharmacies);
    }

    // Handle map focus requests from AppNavigationProvider
    _handleMapFocusRequest();

    // Handle directions result from DirectionsProvider
    _handleDirectionsResult();

    // Listen to location provider for navigation updates
    final locationProvider = context.watch<LocationProvider>();
    if (_isNavigating && locationProvider.currentPosition != null) {
      // Check if this is a new position that we haven't processed for navigation
      if (_lastRouteCalculationPosition == null || 
          (locationProvider.currentPosition!.latitude != _lastRouteCalculationPosition!.latitude ||
           locationProvider.currentPosition!.longitude != _lastRouteCalculationPosition!.longitude)) {
        _onLocationUpdate(locationProvider.currentPosition!);
      }
    }
  }

  void _handleMapFocusRequest() {
    final navProvider = context.watch<AppNavigationProvider>();
    final targetPharmacy = navProvider.targetPharmacyForMapFocus; // Use new getter

    if (navProvider.shouldAnimateMap() && targetPharmacy != null && 
        (targetPharmacy.latitude != null && targetPharmacy.longitude != null)) {
      
      final targetLocation = LatLng(targetPharmacy.latitude!, targetPharmacy.longitude!);

      // Prevent re-focus/re-animation if it's the same pharmacy already selected for nav prep
      // or if it's the same as the last explicitly focused location.
      if ((_selectedPharmacyForNavigation?.id == targetPharmacy.id && _selectedPharmacyForNavigation != null) ||
          (_lastFocusedLocation?.latitude == targetLocation.latitude && 
           _lastFocusedLocation?.longitude == targetLocation.longitude)) {
        // Already focused or selected, clear the request if no longer pending from provider side
        if(!navProvider.shouldAnimateMap()){ // If provider flag was cleared by another interaction
            context.read<AppNavigationProvider>().clearMapFocus();
        }
        // else, map screen might have cleared its own _lastFocusedLocation but provider still pending
        // let it be, or provider.clearMapFocus() will be called later by map screen after animation
        return; 
      }
      
      _lastFocusedLocation = targetLocation;

      // If currently navigating to a different destination, stop it.
      if (_isNavigating && (_navigationDestination != targetLocation)) {
        _stopNavigation();
      }

      // Set this pharmacy as the one selected for navigation (will show FAB)
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

      // Programmatically show the InfoWindow for the focused pharmacy immediately after state update
      // Ensure mapController is available. It might not be on very first init if map is not ready.
      if (_mapController != null) {
         _mapController!.showMarkerInfoWindow(MarkerId(targetPharmacy.id));
      } else {
        // If controller not ready, try to show it once map is created/ready
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
      // If the flag is false but target is still there, means request was handled or became stale.
      // MapScreen might have animated already. Clear it from provider to be safe.
      context.read<AppNavigationProvider>().clearMapFocus();
    }
  }

  void _handleDirectionsResult() {
    final directionsProvider = context.watch<DirectionsProvider>();
    final route = directionsProvider.currentRoute;

    if (route != null && directionsProvider.polylines.isNotEmpty) {
      // If navigating, update the last known position from which route was calculated.
      // This assumes route.origin (if available) or we use current user position
      // For simplicity, _startOrUpdateNavigation and _onLocationUpdate will manage _lastRouteCalculationPosition
      
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
    _stopNavigation(); // Ensure navigation is stopped and resources released
    super.dispose();
  }

  // Function to handle search input changes
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
          _showSearchResults = true; // Show results even if empty for "not found" message
        }
      });
    });
  }

  // Function to reset search and clear directions
  void _clearSearchAndDirections() {
    _searchController.clear();
    _stopNavigation(); // This will also clear directions via provider
    setState(() {
      _searchQuery = '';
      _filteredPharmacies = [];
      _showSearchResults = false;
      // Restore markers from provider - _stopNavigation also calls _updateMarkers
      // _updateMarkers(context.read<PharmacyProvider>().pharmacies); 
    });
    FocusScope.of(context).unfocus(); 
  }

  // Function to move map to a selected pharmacy
  Future<void> _goToPharmacy(Pharmacy pharmacy) async {
    // Check if coordinates are valid before animating
    if (pharmacy.latitude == null || pharmacy.longitude == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location coordinates not available for ${pharmacy.name}.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return; // Don't proceed if coordinates are null
    }

    // If currently navigating, stop the old navigation first
    if (_isNavigating) {
      _stopNavigation();
    }

    setState(() {
      _selectedPharmacyForNavigation = pharmacy;
      // Clear any existing route polylines from a previous selection if not navigating
      // This ensures that if a user clicks another pharmacy before clicking "Get Directions",
      // the old potential route (if any was shown without full navigation) is cleared.
      // However, DirectionsProvider.clearDirections() is part of _stopNavigation and _clearSearchAndDirections
      // If we are not navigating, there shouldn't be persistent polylines managed by DirectionsProvider
      // unless explicitly drawn. For now, just setting the pharmacy is key.
    });

    final LatLng pharmacyLocation = LatLng(pharmacy.latitude!, pharmacy.longitude!);

    // DO NOT start navigation automatically anymore
    // await _startOrUpdateNavigation(pharmacyLocation);

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: pharmacyLocation,
        zoom: 16.0, // Zoom in closer
      ),
    ));

    // Show only the selected marker (or keep all if preferred during navigation)
    // If _isNavigating is true, DirectionsProvider will show route polylines.
    // We might want to keep all pharmacy markers visible, or just the destination.
    // For now, let's stick to showing only the selected one for clarity when choosing.
    // _stopNavigation() will restore all markers.
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

    // Programmatically show the InfoWindow after setting the marker
    _mapController?.showMarkerInfoWindow(MarkerId(pharmacy.id));

    FocusScope.of(context).unfocus();
  }

  // --- New method to animate camera --- 
  Future<void> _animateToLocation(LatLng location) async {
    // Use stored controller if available, otherwise wait for completer
    final GoogleMapController controller = _mapController ?? await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: location,
        zoom: 16.0, // Or desired zoom level
      ),
    ));
     // Maybe also show a single marker temporarily?
     // Or rely on the main marker set updating?
  }

  // --- Helper to update map markers ---
  void _updateMarkers(List<Pharmacy> pharmacies) {
    if (!mounted) return;
    final Set<Marker> newMarkers = pharmacies.where((p) => p.latitude != null && p.longitude != null).map((pharmacy) {
      return Marker(
        markerId: MarkerId(pharmacy.id),
        position: LatLng(pharmacy.latitude!, pharmacy.longitude!),
        infoWindow: InfoWindow(title: pharmacy.name, snippet: pharmacy.isOpen ? 'Open' : 'Closed'),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          // Differentiate selected marker if it's in the main list vs. explicitly selected
          (_selectedPharmacyForNavigation?.id == pharmacy.id) 
              ? BitmapDescriptor.hueYellow 
              : (pharmacy.isOpen ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed),
        ),
        onTap: () {
          // Stop current navigation if any
          if (_isNavigating) {
            _stopNavigation();
          }
          // Set this pharmacy as selected for navigation prep
          setState(() {
            _selectedPharmacyForNavigation = pharmacy;
            // Update markers to highlight only this one
            // This logic is a bit circular with the icon color above, so we ensure it sets the single marker correctly.
            _markers = {
              Marker(
                markerId: MarkerId(pharmacy.id),
                position: LatLng(pharmacy.latitude!, pharmacy.longitude!),
                infoWindow: InfoWindow(title: pharmacy.name, snippet: pharmacy.isOpen ? 'Open' : 'Closed'),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow), // Explicitly yellow
                // The onTap for this re-created marker doesn't need to do anything further,
                // as it's already selected. Or we could make it a no-op.
              )
            };
          });
          // Programmatically show the InfoWindow
          _mapController?.showMarkerInfoWindow(MarkerId(pharmacy.id));
        },
      );
    }).toSet();

    // Only update _markers if not specifically showing a single selected one already
    // This condition might need refinement based on how _selectedPharmacyForNavigation interacts
    // For now, _goToPharmacy and _handleMapFocusRequest set _markers to a single item.
    // _clearPharmacySelection and _stopNavigation call this _updateMarkers with all pharmacies.
    if (_selectedPharmacyForNavigation == null || _markers.length != 1) {
        setState(() {
          _markers = newMarkers;
        });
    }
  }

  // Method to get initial camera position based on provider
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

  // --- Navigation Methods ---
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
      _selectedPharmacyForNavigation = null; // Clear selection once navigation starts
    });

    // Start continuous location updates
    await locationProvider.startLocationUpdates();
    
    // Fetch initial route
    final directionsProvider = context.read<DirectionsProvider>();
    await directionsProvider.findDirections(
        LatLng(locationProvider.currentPosition!.latitude, locationProvider.currentPosition!.longitude), // Origin
        destination); // Destination
    
    // _lastRouteCalculationPosition is already set above
    
    // Optional: Animate camera to user's current location or overview of route
    if (_mapController != null && locationProvider.currentPosition != null) {
         _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
                LatLng(locationProvider.currentPosition!.latitude, locationProvider.currentPosition!.longitude), 
                16.0 // Zoom level
            )
        );
    }
  }

  void _onLocationUpdate(Position newPosition) {
    if (!_isNavigating || _navigationDestination == null || _lastRouteCalculationPosition == null) {
      return;
    }

    // Only recalculate if the new position is different enough
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
          LatLng(newPosition.latitude, newPosition.longitude), // New origin
          _navigationDestination!); // Existing destination
      
      // Optional: Keep map centered on user or let them pan freely
      // if (_mapController != null) {
      //   _mapController!.animateCamera(
      //     CameraUpdate.newLatLng(LatLng(newPosition.latitude, newPosition.longitude)),
      //   );
      // }
    } else {
      // Even if not recalculating route, update current position for potential marker/camera
       // setState(() {
       //   _lastRouteCalculationPosition = newPosition; // Keep it fresh but don't trigger refetch yet
       // });
    }
  }

  void _stopNavigation() {
    if (!_isNavigating && _navigationDestination == null && _selectedPharmacyForNavigation == null) return;

    setState(() {
      _isNavigating = false;
      _navigationDestination = null;
      _lastRouteCalculationPosition = null;
      _selectedPharmacyForNavigation = null; // Also clear selected pharmacy here
    });
    
    // Stop location updates
    // Check if LocationProvider is still mounted/available before calling
    if (mounted) {
        context.read<LocationProvider>().stopLocationUpdates();
        context.read<DirectionsProvider>().clearDirections();
    }


    // Reset markers to show all pharmacies, or as per default state
    final pharmacyProvider = context.read<PharmacyProvider>();
    _updateMarkers(pharmacyProvider.pharmacies); 
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final directionsProvider = context.watch<DirectionsProvider>();

    // Determine dynamic bottom padding for the map
    double currentBottomPadding = 0.0;
    if (_isNavigating) {
      currentBottomPadding = 60.0; // Padding for the single "Stop Navigation" FAB
    } else if (_selectedPharmacyForNavigation != null) {
      currentBottomPadding = 80.0; // Padding for the row of "Get Directions" and "Cancel" FABs
    }

    return Scaffold(
      floatingActionButton: _isNavigating
          ? FloatingActionButton.extended(
              onPressed: _stopNavigation,
              label: const Text('Stop Navigation'),
              icon: const Icon(Icons.close),
              backgroundColor: Colors.redAccent,
              heroTag: 'fabStopNavigation', // Ensure this also has a unique tag if not already present
            )
          : _selectedPharmacyForNavigation != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Center the buttons horizontally
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
                    const SizedBox(width: 16), // Spacing between buttons
                    FloatingActionButton.extended(
                      onPressed: _clearPharmacySelection, 
                      label: const Text('Cancel'), // Shortened label for side-by-side
                      icon: const Icon(Icons.cancel_outlined),
                      backgroundColor: Colors.grey,
                      heroTag: 'fabCancelSelection',
                    ),
                  ],
                )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // Using a Stack to overlay the search bar
      body: Stack(
        children: [
          // Show map only if not loading location initially
          // Or show map centered on default while loading?
          if (!locationProvider.isLoadingLocation)
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _getInitialCameraPosition(
                locationProvider,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller; // Store the controller
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                }
              },
              markers: _markers,
              polylines: directionsProvider.polylines, // Add polylines from provider
              myLocationEnabled: true, // Show user location dot
              myLocationButtonEnabled: true, // Show button to center on user
              onTap: (_) { // Add onTap callback for the map
                _clearPharmacySelection();
              },
              padding: EdgeInsets.only(
                top: 100.0, // Existing top padding for search bar
                bottom: currentBottomPadding, // Dynamically set bottom padding
              ), 
            )
          else // Show loading indicator while location is fetched
            const Center(child: CircularProgressIndicator(color: primaryGreen)),

          // Display Loading Indicator for Directions
          if (directionsProvider.isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ),

          // Display Error Message for Directions
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
                      onPressed: () => directionsProvider.clearDirections(), // Clear error
                    )
                  ],
                ),
              ),
            ),

          // Search Bar and Results Overlay
          Positioned(
            top: 50, // Adjust position as needed (consider SafeArea)
            left: 15,
            right: 15,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search Bar Container
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
                      // Update clear button to also clear directions
                      suffixIcon: _searchQuery.isNotEmpty || directionsProvider.polylines.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: darkGrey),
                              onPressed: _clearSearchAndDirections, // Use new clear function
                            )
                          : null,
                    ),
                    onChanged: _handleMapSearchChanged,
                  ),
                ),
                // Search Results List Overlay (Conditional)
                if (_showSearchResults)
                  Container(
                    margin: const EdgeInsets.only(top: 4.0),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.3, // Limit height
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
                            padding: EdgeInsets.zero, // Remove padding
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
