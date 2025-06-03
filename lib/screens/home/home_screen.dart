import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dwaya_app/providers/location_provider.dart';
import 'package:dwaya_app/utils/colors.dart';
import 'package:dwaya_app/models/pharmacy.dart';
import 'package:dwaya_app/widgets/pharmacy_list_item.dart';
import 'package:dwaya_app/screens/home/map_screen.dart';
import 'package:dwaya_app/screens/profile/profile_screen.dart';
import 'package:dwaya_app/providers/pharmacy_provider.dart';
import 'package:dwaya_app/providers/favorites_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:dwaya_app/providers/app_navigation_provider.dart';

/// Main screen of the app that displays the list of pharmacies and handles navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;
  bool _filterOpenNow = false;
  double? _filterMaxDistance;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Handles bottom navigation bar item selection
  void _onItemTapped(int index) {
    if (_isSearching) {
      setState(() {
        _isSearching = false;
        _searchController.clear();
      });
    }
    context.read<AppNavigationProvider>().navigateToTab(index);
  }

  /// Toggles search bar visibility
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  /// Handles search form submission
  void _handleSearchSubmitted(String value) {
    setState(() {
      _searchQuery = value.trim();
    });
  }

  /// Handles search input changes with debounce
  void _handleSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
          setState(() {
            _searchQuery = value.trim();
          });
      }
    });
  }

  /// Builds the main content based on selected tab
  Widget _buildBody(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final navProvider = context.watch<AppNavigationProvider>();
    final selectedIndex = navProvider.currentTabIndex;
    switch (selectedIndex) {
      case 0:
        return HomePageContent(
          searchQuery: _searchQuery,
          filterOpenNow: _filterOpenNow,
          onFilterChanged: (isOpen) {
            setState(() {
              _filterOpenNow = isOpen;
            });
          },
        );
      case 1:
        return MapScreen();
      case 2:
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
      case 3:
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
        );
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
                      : [
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
            icon: Icon(Icons.favorite_border),
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
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

/// Widget that displays the main content of the home tab
class HomePageContent extends StatefulWidget {
  final String searchQuery;
  final bool filterOpenNow;
  final ValueChanged<bool> onFilterChanged;
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
  bool _initialFetchDone = false;
  double? _selectedMaxDistance;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchPharmaciesIfNeeded();
      }
    });
  }

  /// Fetches pharmacies if location is available and initial fetch not done
  void _fetchPharmaciesIfNeeded() {
    final locationProvider = context.read<LocationProvider>();
    final pharmacyProvider = context.read<PharmacyProvider>();
    final currentLocation = locationProvider.currentPosition;
    if (currentLocation != null &&
        !locationProvider.isLoadingLocation &&
        !_initialFetchDone) {
      pharmacyProvider.fetchAndSetPharmacies(
        LatLng(currentLocation.latitude, currentLocation.longitude),
      );
      setState(() {
        _initialFetchDone = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final pharmacyProvider = context.watch<PharmacyProvider>();
    final locationIsLoading = locationProvider.isLoadingLocation;
    final serviceDisabled = locationProvider.locationServiceInitiallyDisabled;
    final permissionDenied = locationProvider.locationPermissionDenied;
    final pharmacyIsLoading = pharmacyProvider.isLoading;
    final pharmacies = pharmacyProvider.pharmacies;
    final pharmacyError = pharmacyProvider.errorMessage;
    final locationError = locationProvider.errorMessage;
    List<Pharmacy> filteredPharmacies = pharmacies;
    if (widget.filterOpenNow) {
      filteredPharmacies = filteredPharmacies.where((p) => p.isOpen).toList();
    }
    if (_selectedMaxDistance != null) {
      filteredPharmacies = filteredPharmacies.where((p) {
        return p.distance != null && p.distance! <= _selectedMaxDistance!;
      }).toList();
    }
    if (widget.searchQuery.isNotEmpty) {
        filteredPharmacies = filteredPharmacies.where((pharmacy) {
        final queryLower = widget.searchQuery.toLowerCase();
        final nameLower = pharmacy.name.toLowerCase();
        final addressLower = pharmacy.address.toLowerCase();
        return nameLower.contains(queryLower) || addressLower.contains(queryLower);
      }).toList();
    }
    if (locationIsLoading && !_initialFetchDone) {
      return const Center(
        child: Text('Getting location...'),
      );
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
      );
    }
    if (filteredPharmacies.isEmpty && _initialFetchDone) {
      return Center(child: Text(
          widget.searchQuery.isEmpty
              ? 'No pharmacies found nearby.'
              : 'No pharmacies found matching "${widget.searchQuery}".'
      ));
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          color: primaryGreen.withAlpha(26),
          width: double.infinity,
          child: const Row(
            children: [
              Icon(Icons.campaign_outlined, color: primaryGreen),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Special offers available now! Check details.',
                  style: TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkGrey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilterChip(
                    label: const Text('Open Now'),
                    selected: widget.filterOpenNow,
                    onSelected: widget.onFilterChanged,
                    selectedColor: primaryGreen.withAlpha(50),
                    checkmarkColor: primaryGreen,
                    side: BorderSide(color: widget.filterOpenNow ? primaryGreen : Colors.grey),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  ),
                ],
              ),
              const SizedBox(height: 4),
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
                      isExpanded: true,
                      underline: Container(
                        height: 1,
                        color: Colors.grey[400],
                      ),
                      hint: const Text('Any'),
                      onChanged: (double? newValue) {
                        setState(() {
                          _selectedMaxDistance = newValue;
                        });
                      },
                      items: <DropdownMenuItem<double?>>[
                        const DropdownMenuItem<double?>(
                          value: null,
                          child: Text('Any'),
                        ),
                        const DropdownMenuItem<double?>(
                          value: 1000.0,
                          child: Text('1 km'),
                        ),
                        const DropdownMenuItem<double?>(
                          value: 3000.0,
                          child: Text('3 km'),
                        ),
                        const DropdownMenuItem<double?>(
                          value: 5000.0,
                          child: Text('5 km'),
                        ),
                        const DropdownMenuItem<double?>(
                          value: 10000.0,
                          child: Text('10 km'),
                        ),
                        const DropdownMenuItem<double?>(
                          value: 15000.0,
                          child: Text('15 km'),
                        ),
                        const DropdownMenuItem<double?>(
                          value: 20000.0,
                          child: Text('20 km'),
                        ),
                        const DropdownMenuItem<double?>(
                          value: 25000.0,
                          child: Text('25 km'),
                        ),
                        const DropdownMenuItem<double?>(
                          value: 50000.0,
                          child: Text('50 km'),
                        ),
                        const DropdownMenuItem<double?>(
                          value: 75000.0,
                          child: Text('75 km'),
                        ),
                        const DropdownMenuItem<double?>(
                          value: 100000.0,
                          child: Text('100 km'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: _buildPharmacyList(context, filteredPharmacies),
        ),
      ],
    );
  }
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
  Widget _buildPharmacyList(BuildContext context, List<Pharmacy> pharmacies) {
    return RefreshIndicator(
      onRefresh: () async {
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
            const AlwaysScrollableScrollPhysics(),
        itemCount: pharmacies.length,
        itemBuilder: (context, index) {
          return PharmacyListItem(pharmacy: pharmacies[index]);
        },
      ),
    );
  }
}