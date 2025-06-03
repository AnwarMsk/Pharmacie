import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dwaya_app/providers/auth_provider.dart';
import 'package:dwaya_app/providers/location_provider.dart';
import 'package:dwaya_app/providers/pharmacy_provider.dart';
import 'package:dwaya_app/providers/favorites_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:dwaya_app/widgets/auth_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:dwaya_app/utils/connectivity_helper.dart';
import 'package:dwaya_app/utils/error_reporter.dart';
import 'initializers/mobile_initializer.dart' if (dart.library.html) 'initializers/web_initializer.dart' as initializer;
import 'package:dwaya_app/providers/app_navigation_provider.dart';
import 'package:dwaya_app/providers/directions_provider.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ErrorReporter().initialize(
    reportCallback: (errorData) {
      debugPrint('Error captured: ${errorData['error']}');
    }
  );
  try {
    initializer.platformSpecificInitialization();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stack) {
    ErrorReporter().reportError(e, stack, context: 'App Initialization');
  }
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityHelper()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
          create: (_) => FavoritesProvider(),
          update: (_, auth, previousFavorites) =>
            previousFavorites!..updateAuth(auth.isAuthenticated, auth.currentUser?.uid),
        ),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => PharmacyProvider()),
        ChangeNotifierProvider(create: (_) => AppNavigationProvider()),
        ChangeNotifierProvider(create: (_) => DirectionsProvider()),
      ],
      child: MaterialApp(
        title: 'Dwaya Pharmacy',
        theme: ThemeData(
          primarySwatch:
              Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
            },
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const ConnectivityWidget(
          child: AuthWrapper(),
          showOfflineSnackbar: true,
        ),
        builder: (context, child) {
          return Builder(
            builder: (context) {
              ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                ErrorReporter().reportFlutterError(errorDetails);
                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Error'),
                    backgroundColor: Colors.red,
                  ),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Something went wrong',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            kReleaseMode
                              ? 'Please try again later or contact support.'
                              : errorDetails.exception.toString(),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                            child: const Text('Return to Home'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              };
              return child!;
            },
          );
        },
      ),
    );
  }
}