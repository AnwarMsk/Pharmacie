import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:dwaya_app/utils/colors.dart';
// Import login screen later for navigation
import 'package:dwaya_app/screens/auth/login_screen.dart';
import 'package:dwaya_app/services/location_service.dart'; // Import the service
import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool _isLastPage = true; // Always true for a single page
  final LocationService _locationService = LocationService();
  bool _isLoading = false; // Add loading state for finish/skip action

  // Method to handle final navigation (Skip or Get Started)
  void _finishOnboarding() async {
    // Prevent multiple clicks while processing
    if (_isLoading) return;

    setState(() {
      _isLoading = true; // Set loading state
    });

    bool permissionGranted = false; // Default to false
    try {
      // Only request permission if NOT on web
      if (!kIsWeb) {
        permissionGranted = await _locationService.requestLocationPermission();
      } else {
        // Optionally, you could try HTML5 geolocation here if needed,
        // but permission_handler doesn't support it directly.
      }
    } catch (e) {
      // Handle error appropriately, maybe show a message
      if (mounted) { // Show snackbar on error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not request location permission.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    }

    if (mounted) {
      // Check before proceeding after await
      if (permissionGranted) {
      } else {
        // Consider showing a message explaining the need for location
      }

      // Navigate regardless of permission (as per current logic)
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      // No need to set _isLoading = false as we are navigating away
    } else {
      // Widget was disposed before navigation could happen
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Disable scrolling for a single page
            children: const [
              OnboardingPageWidget(
                imagePlaceholderColor: Colors.blueGrey,
                title: 'Find pharmacy near you',
                description:
                    "It's easy to find pharmacy that is near to your location. With just one tap.",
              ),
            ],
          ),
          Container(
            alignment: const Alignment(0, 0.75),
            child: SmoothPageIndicator(
              controller: _pageController,
              count: 1, // Updated count to 1
              effect: const WormEffect(
                dotHeight: 10,
                dotWidth: 10,
                activeDotColor: primaryGreen,
                dotColor: mediumGrey,
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center the button
              children: [
                // Conditional Button: Next or Get Started
                ElevatedButton(
                  // Always call _finishOnboarding, disable if loading
                  onPressed: _isLoading ? null : _finishOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // Show loading indicator or text
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(white),
                          ),
                        )
                      : const Text( // Always show "Get Started" or similar
                          'Get Started',
                          style: TextStyle(fontSize: 16),
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

// Reusable Widget for each onboarding page
class OnboardingPageWidget extends StatelessWidget {
  final Color imagePlaceholderColor;
  final String title;
  final String description;

  const OnboardingPageWidget({
    super.key,
    required this.imagePlaceholderColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    // Define the image widget separately for clarity
    Widget imageDisplay = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        'assets/images/onboarding.png', 
        height: 250,
        // For web, width will be constrained by ConstrainedBox, so set to null or rely on BoxFit.cover.
        // For mobile, it takes full width.
        width: kIsWeb ? null : double.infinity, 
        fit: BoxFit.cover, 
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Placeholder for Image
          if (kIsWeb) // Conditional layout for web
            Center( // Center the constrained image on web
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500), // Set a max width for web
                child: imageDisplay,
              ),
            )
          else // Original layout for mobile
            imageDisplay,
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: black,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: darkGrey),
          ),
          const SizedBox(height: 100), // Space for indicator and buttons
        ],
      ),
    );
  }
}
