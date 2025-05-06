import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:dwaya_app/providers/auth_provider.dart'; // Import AuthProvider
import 'package:dwaya_app/providers/location_provider.dart'; // Import LocationProvider
import 'package:dwaya_app/providers/pharmacy_provider.dart'; // Import PharmacyProvider
import 'package:dwaya_app/providers/favorites_provider.dart'; // Import FavoritesProvider
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'firebase_options.dart'; // Import generated options
import 'package:dwaya_app/widgets/auth_wrapper.dart'; // Import the AuthWrapper
import 'package:flutter/foundation.dart'; // Import for kIsWeb

// Conditionally import the platform-specific initializer
// We need separate files again to avoid importing dart:html on mobile
import 'initializers/mobile_initializer.dart' if (dart.library.html) 'initializers/web_initializer.dart' as initializer;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); 

  // Call the platform-specific initialization function
  // This will ensure the script is injected even in release builds for this test.
  initializer.platformSpecificInitialization();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
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
