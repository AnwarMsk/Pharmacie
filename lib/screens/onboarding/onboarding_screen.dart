import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:dwaya_app/utils/colors.dart';
import 'package:dwaya_app/screens/auth/login_screen.dart';
import 'package:dwaya_app/services/location_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}
class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final LocationService _locationService = LocationService();
  bool _isLoading = false;
  void _finishOnboarding() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    bool permissionGranted = false;
    try {
      if (!kIsWeb) {
        permissionGranted = await _locationService.requestLocationPermission();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not request location permission.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    }
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen())
      );
    } else {
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
            physics: const NeverScrollableScrollPhysics(),
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
              count: 1,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
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
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(white),
                          ),
                        )
                      : const Text(
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
    Widget imageDisplay = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        'assets/images/onboarding.png',
        height: 250,
        width: kIsWeb ? null : double.infinity,
        fit: BoxFit.cover,
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (kIsWeb)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: imageDisplay,
              ),
            )
          else
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
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}