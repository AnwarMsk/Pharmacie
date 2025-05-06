import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dwaya_app/utils/colors.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:dwaya_app/providers/location_provider.dart'; // Import LocationProvider
import 'package:url_launcher/url_launcher.dart';
import 'package:dwaya_app/providers/pharmacy_provider.dart'; // Import PharmacyProvider
import 'dart:async'; // Import Timer

import 'package:dwaya_app/models/pharmacy.dart';

class MapScreen extends StatefulWidget {
  // Remove userPosition parameter
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  // State for pharmacy search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Pharmacy> _filteredPharmacies = [];
  Timer? _debounce;
  bool _showSearchResults = false; // To control visibility of results list

  // Make markers a state variable
  Set<Marker> _markers = {};

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
    // Update markers with the currently loaded list from PharmacyProvider
    // This assumes PharmacyProvider has already fetched data (likely triggered by HomeScreen)
    final initialPharmacies = context.read<PharmacyProvider>().pharmacies;
    _updateMarkers(initialPharmacies);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
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

  // Function to reset search and restore all nearby markers
  void _clearSearchAndRestoreMarkers() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filteredPharmacies = [];
      _showSearchResults = false;
      // Restore markers from provider
      _updateMarkers(context.read<PharmacyProvider>().pharmacies);
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

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        // Use non-null assertion (!) since we checked for null above
        target: LatLng(pharmacy.latitude!, pharmacy.longitude!),
        zoom: 16.0, // Zoom in closer
      ),
    ));

    // Show only the selected marker
    final selectedMarker = Marker(
      markerId: MarkerId(pharmacy.id),
      position: LatLng(pharmacy.latitude!, pharmacy.longitude!),
      infoWindow: InfoWindow(title: pharmacy.name, snippet: pharmacy.isOpen ? 'Open' : 'Closed'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow), // Highlight color
    );
    setState(() {
      _markers = {selectedMarker};
      _searchController.clear(); // Clear text field
      _searchQuery = ''; // Clear query state
      _filteredPharmacies = []; // Clear filtered list
      _showSearchResults = false; // Hide results overlay
    });

    // Hide keyboard
    FocusScope.of(context).unfocus();
  }

  // --- Helper to update map markers ---
  void _updateMarkers(List<Pharmacy> pharmacies) {
    if (!mounted) return;
    final Set<Marker> newMarkers = pharmacies.where((p) => p.latitude != null && p.longitude != null).map((pharmacy) {
      return Marker(
        markerId: MarkerId(pharmacy.id),
        position: LatLng(pharmacy.latitude!, pharmacy.longitude!),
        infoWindow: InfoWindow(title: pharmacy.name, snippet: pharmacy.isOpen ? 'Open' : 'Closed'),
        // Optional: Add custom icon based on open status or favorite status?
      icon: BitmapDescriptor.defaultMarkerWithHue(
          pharmacy.isOpen ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
        onTap: () {
          // Optional: Show more details or animate camera on marker tap
        },
      );
    }).toSet();

    setState(() {
      _markers = newMarkers;
    });
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

  @override
  Widget build(BuildContext context) {
    // Watch LocationProvider state
    final locationProvider = context.watch<LocationProvider>();

    return Scaffold(
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
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                }
              },
              markers: _markers,
              myLocationEnabled: true, // Show user location dot
              myLocationButtonEnabled: true, // Show button to center on user
              padding: const EdgeInsets.only(
                top: 100.0,
                bottom: 0,
              ), // Adjust padding for overlay/buttons
            )
          else // Show loading indicator while location is fetched
            const Center(child: CircularProgressIndicator(color: primaryGreen)),

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
                      // Add clear button if query is not empty
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: darkGrey),
                              onPressed: _clearSearchAndRestoreMarkers, // Call clear function
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
