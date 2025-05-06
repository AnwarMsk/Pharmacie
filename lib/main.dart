import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:dwaya_app/providers/auth_provider.dart'; // Import AuthProvider
import 'package:dwaya_app/providers/location_provider.dart'; // Import LocationProvider
import 'package:dwaya_app/providers/pharmacy_provider.dart'; // Import PharmacyProvider
import 'package:dwaya_app/providers/favorites_provider.dart'; // Import FavoritesProvider
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'firebase_options.dart'; // Import generated options
import 'package:dwaya_app/widgets/auth_wrapper.dart'; // Import the AuthWrapper

// Import foundation for kIsWeb and kReleaseMode
import 'package:flutter/foundation.dart'; 
// Import dart:html for web-specific checks and DOM manipulation
import 'dart:html' as html; 

Future<void> main() async {
  // Make main asynchronous
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized

  // --- Manually inject Google Maps script for web builds --- START
  if (kIsWeb) { 
    const apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    if (apiKey.isNotEmpty) {
      // Construct the script URL
      // Add libraries=places if you use Places Autocomplete or SearchBox
      final scriptUrl = 'https://maps.googleapis.com/maps/api/js?key=$apiKey'; 

      // Check if script already exists (e.g., due to hot restart)
      if (html.document.querySelector('script[src="$scriptUrl"]') == null) {
        final script = html.ScriptElement()
          ..id = 'google-maps-sdk' // Optional ID
          ..src = scriptUrl
          ..async = true
          ..defer = true;
        // print('Injecting Google Maps script for local web run...');
        html.document.head?.append(script);
      }
    } else {
      // print('Google Maps API Key not provided via --dart-define for local web run.');
      // You might want to throw an error or show a message if the key is essential
    }
  }
  // --- Manually inject Google Maps script for local web dev --- END

  await Firebase.initializeApp(
    // Initialize Firebase
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    // Wrap the app with MultiProvider
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(
          create: (_) => PharmacyProvider(),
        ), // Add PharmacyProvider
        ChangeNotifierProvider(create: (_) => FavoritesProvider()), // Add FavoritesProvider
        // Add other providers here if needed
      ],
      child: const MyApp(), // Your original root widget
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dwaya Pharmacy',
      theme: ThemeData(
        // Define the default brightness and colors.
        primarySwatch:
            Colors.green, // Or create a custom swatch from primaryGreen
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Define the default font family (optional)
        // fontFamily: 'Georgia',
      ),
      debugShowCheckedModeBanner: false, // Remove debug banner
      home: const AuthWrapper(), // Start with the AuthWrapper
    );
  }
}
