import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:dwaya_app/providers/location_provider.dart'; // Import LocationProvider
import 'package:dwaya_app/utils/colors.dart';
import 'package:dwaya_app/models/pharmacy.dart';
import 'package:dwaya_app/widgets/pharmacy_list_item.dart';
import 'package:dwaya_app/screens/home/map_screen.dart';
import 'package:dwaya_app/screens/profile/profile_screen.dart'; // Import ProfileScreen
import 'package:dwaya_app/providers/pharmacy_provider.dart'; // Import PharmacyProvider
import 'package:dwaya_app/providers/favorites_provider.dart'; // Import FavoritesProvider
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import LatLng
import 'dart:async'; // Import Timer
import 'package:dwaya_app/providers/app_navigation_provider.dart'; // Import AppNavigationProvider

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ''; // Add state for the search query
  Timer? _debounce; // Timer for debouncing search input
  bool _filterOpenNow = false; // State for filtering open pharmacies
  double? _filterMaxDistance; // State for filtering distance (meters), null means Any

  // Remove local location state and service instance
  // Position? _currentPosition;
  // bool _isLoadingLocation = true;
  // final LocationService _locationService = LocationService();

  // Remove _widgetOptions - will build dynamically based on provider state
  // late List<Widget> _widgetOptions;

  // Remove initState and related methods (_initializeWidgetOptions, _fetchInitialLocation, _showEnableLocationDialog)
  // Location fetching is now handled by LocationProvider

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel(); // Cancel the debounce timer
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_isSearching) {
      setState(() {
        _isSearching = false;
        _searchController.clear();
      });
    }
    // Use provider to change tab
    context.read<AppNavigationProvider>().navigateToTab(index);
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = ''; // Clear query when closing search
      }
      // Maybe trigger a refresh or filter update here if needed
    });
  }

  // Update search query state on submit
  void _handleSearchSubmitted(String value) {
    setState(() {
      _searchQuery = value.trim();
    });
    // Remove navigation to SearchResultsScreen
    // if (value.isNotEmpty) {
    //   Navigator.of(context).push(
    //     MaterialPageRoute(
    //       builder: (_) => SearchResultsScreen(searchQuery: value),
    //     ),
    //   );
    // }
  }

  // Update search query state as user types with debouncing
  void _handleSearchChanged(String value) {
    // Cancel the previous timer if it exists
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Start a new timer
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // This code runs after 500ms of no typing
      if (mounted) { // Check if widget is still in the tree
          setState(() {
            _searchQuery = value.trim();
          });
      }
    });

    // Don't update state immediately anymore
    // setState(() {
    //   _searchQuery = value.trim();
    // });
  }

  // Helper method to build the body content based on selected index and provider state
  Widget _buildBody(BuildContext context) {
    // Watch LocationProvider for changes
    final locationProvider = context.watch<LocationProvider>();
    // Watch AppNavigationProvider for tab index
    final navProvider = context.watch<AppNavigationProvider>();
    final selectedIndex = navProvider.currentTabIndex;

    switch (selectedIndex) {
      case 0: // Home
        return HomePageContent(
          searchQuery: _searchQuery,
          filterOpenNow: _filterOpenNow,
          onFilterChanged: (isOpen) {
            setState(() {
              _filterOpenNow = isOpen;
            });
          },
        );
      case 1: // Map/Search
        return MapScreen(); // MapScreen will get location from provider
      case 2: // Favorites
        return Consumer2<PharmacyProvider, FavoritesProvider>(
          builder: (context, pharmacyProvider, favoritesProvider, child) {
            final favoriteIds = favoritesProvider.favoritePharmacyIds;
            final favoritePharmacies = pharmacyProvider.pharmacies
                .where((p) => favoriteIds.contains(p.id))
                .toList();

            if (favoritePharmacies.isEmpty) {
              return const Center(
                child: Text(
                  'No favorite pharmacies found.\nAdd some by tapping the heart icon!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }
            return ListView.builder(
              itemCount: favoritePharmacies.length,
              itemBuilder: (context, index) {
                return PharmacyListItem(pharmacy: favoritePharmacies[index]);
              },
            );
          },
        );
      case 3: // Profile (was case 4)
        return const ProfileScreen(); 
      default:
        return HomePageContent(
          searchQuery: _searchQuery,
          filterOpenNow: _filterOpenNow,
          onFilterChanged: (isOpen) {
            setState(() {
              _filterOpenNow = isOpen;
            });
          },
        ); // Default to Home
    }
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<AppNavigationProvider>();
    final selectedIndex = navProvider.currentTabIndex;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: white,
        elevation: 1,
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search pharmacies...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: darkGrey),
                  ),
                  onSubmitted: _handleSearchSubmitted,
                  onChanged: _handleSearchChanged,
                )
                : Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Image.asset('assets/images/logo.png', height: 28),
                ),
        actions:
            _isSearching
                ? [
                  IconButton(
                    icon: const Icon(Icons.close, color: black),
                    onPressed: _toggleSearch,
                  ),
                ]
                : (
                  selectedIndex != 1 
                      ? [
                          IconButton(
                            icon: const Icon(Icons.search, color: black),
                            onPressed: _toggleSearch,
                          ),
                        ]
                      : [ // Show filter button only on Map tab (index 1) and when not searching
                          // This is an example, you might want to place it elsewhere or handle filters differently on map
                          // IconButton(
                          //   icon: const Icon(Icons.filter_list, color: black),
                          //   onPressed: () {
                          //     // TODO: Implement filter action for map if different from home
                          //   },
                          // ),
                        ]
                ),
      ),
      body: _buildBody(context),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border), // Corrected from favorite_outline if it was changed
            activeIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: selectedIndex,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey, // Ensured this is Colors.grey
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// --- Update HomePageContent ---

class HomePageContent extends StatefulWidget {
  final String searchQuery;
  final bool filterOpenNow; // Add filter state
  final ValueChanged<bool> onFilterChanged; // Add callback

  const HomePageContent({
    super.key,
    required this.searchQuery,
    required this.filterOpenNow,
    required this.onFilterChanged,
  });

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  bool _initialFetchDone = false; // Flag to prevent multiple fetches

  // Add state for distance dropdown
  double? _selectedMaxDistance; // Null represents 'Any' distance

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // _fetchPharmaciesIfNeeded(); // Call fetch logic here <-- OLD WAY
    // Ensure fetch happens after the current build frame is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Check if the widget is still in the tree
        _fetchPharmaciesIfNeeded();
      }
    });
  }

  void _fetchPharmaciesIfNeeded() {
    // Get providers without listening here (just reading)
    final locationProvider = context.read<LocationProvider>();
    final pharmacyProvider = context.read<PharmacyProvider>();
    final currentLocation = locationProvider.currentPosition;

    // Fetch only if location is available, not loading, and fetch hasn't been done yet
    if (currentLocation != null &&
        !locationProvider.isLoadingLocation &&
        !_initialFetchDone) {
      pharmacyProvider.fetchAndSetPharmacies(
        LatLng(currentLocation.latitude, currentLocation.longitude),
      );
      setState(() {
        _initialFetchDone = true;
      }); // Mark fetch as done
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch LocationProvider state
    final locationProvider = context.watch<LocationProvider>();
    // Watch PharmacyProvider state
    final pharmacyProvider = context.watch<PharmacyProvider>();

    final locationIsLoading = locationProvider.isLoadingLocation;
    final serviceDisabled = locationProvider.locationServiceInitiallyDisabled;
    final permissionDenied = locationProvider.locationPermissionDenied;

    // Get pharmacy state
    final pharmacyIsLoading = pharmacyProvider.isLoading;
    final pharmacies = pharmacyProvider.pharmacies;
    final pharmacyError = pharmacyProvider.errorMessage;
    final locationError = locationProvider.errorMessage; // Get location error

    // Apply filters
    List<Pharmacy> filteredPharmacies = pharmacies;

    // Apply 'Open Now' filter
    if (widget.filterOpenNow) {
      filteredPharmacies = filteredPharmacies.where((p) => p.isOpen).toList();
    }

    // Apply distance filter based on dropdown state
    if (_selectedMaxDistance != null) {
      filteredPharmacies = filteredPharmacies.where((p) {
        // Only include pharmacies with a valid distance within the range
        return p.distance != null && p.distance! <= _selectedMaxDistance!;
      }).toList();
    }

    // Apply search query filter (on top of other filters)
    if (widget.searchQuery.isNotEmpty) {
        filteredPharmacies = filteredPharmacies.where((pharmacy) {
        final queryLower = widget.searchQuery.toLowerCase();
        final nameLower = pharmacy.name.toLowerCase();
        final addressLower = pharmacy.address.toLowerCase();
        // Simple search: check name or address contains query
        return nameLower.contains(queryLower) || addressLower.contains(queryLower);
      }).toList();
    }

    // Check location status first (as before)
    if (locationIsLoading && !_initialFetchDone) {
      return const Center(
        child: Text('Getting location...'),
      ); // More specific text
    }
    if (serviceDisabled) {
      return _buildLocationMessage(
        context,
        'Location services are disabled. Please enable them in your device settings to find nearby pharmacies.',
        'Open Location Settings',
        () => locationProvider.openLocationSettings(),
      );
    }
    if (permissionDenied) {
      return _buildLocationMessage(
        context,
        'Location permission is required to find nearby pharmacies. Please grant permission.',
        'Request Permission',
        () => locationProvider.requestPermission(),
      );
    }

    // Add check for generic location error
    if (locationError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Error getting location: \n$locationError',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    // Now check pharmacy fetch status
    if (pharmacyIsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryGreen),
      );
    }

    if (pharmacyError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Error loading pharmacies: \n$pharmacyError',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ); // Show error from provider
    }

    // Update empty check to use filtered list
    if (filteredPharmacies.isEmpty && _initialFetchDone) {
      // Ensure location wasn't loading before showing "No pharmacies"
      return Center(child: Text(
          widget.searchQuery.isEmpty
              ? 'No pharmacies found nearby.'
              : 'No pharmacies found matching "${widget.searchQuery}".'
      ));
    }

    // --- Build the main content ---

    // TODO: Fetch pharmacies based on currentPosition (or show all if null?)
    // Replace dummy data with fetched data later
    // final List<Pharmacy> _pharmacies = [...]; // REMOVE DUMMY DATA

    return Column(
      children: [
        // Refined Header (e.g., a promotional banner)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          color: primaryGreen.withAlpha(26), // Use withAlpha instead
          width: double.infinity,
          child: const Row(
            children: [
              Icon(Icons.campaign_outlined, color: primaryGreen),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Special offers available now! Check details.', // Example text
                  style: TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- Filters Section --- START
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0), // Add top padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkGrey),
              ),
              const SizedBox(height: 8),
              // Row for "Open Now" Filter Chip
              Row(
                children: [
                  FilterChip(
                    label: const Text('Open Now'),
                    selected: widget.filterOpenNow,
                    onSelected: widget.onFilterChanged,
                    selectedColor: primaryGreen.withAlpha(50),
                    checkmarkColor: primaryGreen,
                    side: BorderSide(color: widget.filterOpenNow ? primaryGreen : Colors.grey),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0), // Adjust padding
                  ),
                  // Add Spacer if needed, or keep simple
                ],
              ),
              const SizedBox(height: 4), // Space between filters

              // --- Row for Distance Dropdown --- START
              Row(
                children: [
                  const Text(
                    'Max Distance:',
                    style: TextStyle(fontSize: 14, color: darkGrey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<double?>(
                      value: _selectedMaxDistance,
                      isExpanded: true, // Allow dropdown to expand
                      underline: Container( // Custom underline
                        height: 1,
                        color: Colors.grey[400],
                      ),
                      hint: const Text('Any'), // Show 'Any' when null
                      onChanged: (double? newValue) {
                        setState(() {
                          _selectedMaxDistance = newValue;
                        });
                      },
                      items: <DropdownMenuItem<double?>>[
                        // Option for 'Any' distance (value is null)
                        const DropdownMenuItem<double?>(
                          value: null,
                          child: Text('Any'),
                        ),
                        // Options for specific distances (value in meters)
                        const DropdownMenuItem<double?>(
                          value: 1000.0, // 1km
                          child: Text('1 km'),
                        ),
                        const DropdownMenuItem<double?>(
                          value: 3000.0, // 3km
                          child: Text('3 km'),
                        ),
                        const DropdownMenuItem<double?>(
                          value: 5000.0, // 5km
                          child: Text('5 km'),
                        ),
                        const DropdownMenuItem<double?>(
                          value: 10000.0, // 10km
                          child: Text('10 km'),
                        ),
                        const DropdownMenuItem<double?>(
                          value: 15000.0, // 15km
                          child: Text('15 km'),
                        ),
                        const DropdownMenuItem<double?>(
                          value: 20000.0, // 20km
                          child: Text('20 km'),
                        ),
                        const DropdownMenuItem<double?>(
                          value: 25000.0, // 25km
                          child: Text('25 km'),
                        ),
                        const DropdownMenuItem<double?>(
                          value: 50000.0, // 50km
                          child: Text('50 km'),
                        ),
                        const DropdownMenuItem<double?>(
                          value: 75000.0, // 75km
                          child: Text('75 km'),
                        ),
                        const DropdownMenuItem<double?>(
                          value: 100000.0, // 100km
                          child: Text('100 km'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // --- Row for Distance Dropdown --- END

            ],
          ),
        ),
        // --- Filters Section --- END

        const Divider(height: 1, thickness: 1), // Divider below filters

        // Pharmacy List Area
        Expanded(
          child: _buildPharmacyList(context, filteredPharmacies),
        ),
      ],
    );
  }

  // Helper for location status messages
  Widget _buildLocationMessage(
    BuildContext context,
    String message,
    String buttonText,
    VoidCallback onPressed,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: darkGrey, fontSize: 15),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: onPressed,
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  // Updated helper method using provider state
  // Removed unused parameters (isLoading, position, serviceDisabled, permissionDenied)
  Widget _buildPharmacyList(BuildContext context, List<Pharmacy> pharmacies) {
    // Loading, error, and empty states are handled in the build method now

    // Use the passed (already filtered) list
    // final List<Pharmacy> displayList = pharmacies;

    return RefreshIndicator(
      onRefresh: () async {
        // Trigger a new fetch when user pulls down
        final locationProvider = context.read<LocationProvider>();
        final currentLocation = locationProvider.currentPosition;
        if (currentLocation != null) {
          await context.read<PharmacyProvider>().fetchAndSetPharmacies(
            LatLng(currentLocation.latitude, currentLocation.longitude),
          );
        }
      },
      child: ListView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(), // Ensure list is always scrollable for RefreshIndicator
        itemCount: pharmacies.length, // Use count from filtered list
        itemBuilder: (context, index) {
          return PharmacyListItem(pharmacy: pharmacies[index]); // Use item from filtered list
        },
      ),
    );
  }
}
