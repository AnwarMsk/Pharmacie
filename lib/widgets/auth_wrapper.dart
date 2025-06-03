import 'package:dwaya_app/providers/auth_provider.dart';
import 'package:dwaya_app/screens/home/home_screen.dart';
import 'package:dwaya_app/screens/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A widget that handles authentication state and shows either HomeScreen or OnboardingScreen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.isAuthenticated) {
      return const HomeScreen();
    } else {
      return const OnboardingScreen();
    }
  }
}