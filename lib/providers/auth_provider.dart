import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:flutter/services.dart'; // Import for PlatformException

// Keep GoogleSignIn initialization for the sign-in flow itself
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email'],
  // For web, you MUST pass the Web client ID from your Google Cloud Console.
  clientId: "449259807974-179fkrlkvpmhgedqfj53qb1a5l6dspsj.apps.googleusercontent.com",
  // clientId parameter removed for native Android, relying on google-services.json
);

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance
  User? _currentUser; // Changed to Firebase User
  bool _isSigningIn = false;
  String? _errorMessage; // Add error message state

  User? get currentUser => _currentUser; // Changed getter type
  bool get isSigningIn => _isSigningIn;
  String? get errorMessage => _errorMessage; // Add getter
  // Check Firebase user for authentication status
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    // Listen to Firebase auth state changes
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      if (_currentUser != null) {
        // Optionally load additional user profile data here
      } else {
        // User is signed out
      }
      notifyListeners(); // Notify listeners about the change
    });
  }

  Future<bool> signInWithGoogle() async {
    if (_isSigningIn) return false;
    _isSigningIn = true;
    _errorMessage = null; // Clear previous error
    notifyListeners();

    bool success = false;
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Create a new credential for Firebase
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        final UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );

        // No need to manually set _currentUser, authStateChanges listener handles it
        if (userCredential.user != null) {
          success = true;
        }
      } else {
        // User cancelled the sign-in flow
        _errorMessage = "Google Sign-In was cancelled.";
      }
    } on PlatformException catch (e) {
      // Handle specific platform errors from Google Sign-In
      // Using string literals for error codes as constants might not be available
      if (e.code == 'sign_in_cancelled') {
        _errorMessage = "Google Sign-In was cancelled.";
      } else if (e.code == 'network_error') {
        _errorMessage = "A network error occurred during Google Sign-In. Please check your connection.";
      } else {
        // For other PlatformExceptions, provide a generic message including the code for debugging
        _errorMessage = "Google Sign-In failed. Error: ${e.message ?? e.code}";
      }
      print('AuthProvider: PlatformException during Google Sign-In: ${e.code} - ${e.message}'); // Added for more logging
    } catch (error, stackTrace) { // Added stackTrace
      // Catch-all for other errors (e.g., Firebase related after Google Sign-In part)
      print('AuthProvider: Caught unexpected error during Google Sign-In:');
      print('Error object: $error');
      print('Error runtimeType: ${error.runtimeType}');
      print('StackTrace: $stackTrace'); // Added stackTrace logging
      _errorMessage = "An unexpected error occurred during Google Sign-In. Please try again.";
    } finally {
      _isSigningIn = false;
      notifyListeners();
    }
    return success;
  }

  Future<void> signOut() async {
    _errorMessage = null; // Clear previous error
    try {
      // Sign out from Firebase
      await _auth.signOut();
      // Also sign out from Google to ensure the user can select a different account next time
      await _googleSignIn.signOut();
    } catch (error) {
      _errorMessage = "Sign out failed. Please try again.";
      // Consider logging the original error for debugging: print("AuthProvider: Error signing out: $error");
    }
    notifyListeners();
  }

  Future<bool> signInWithEmailPassword(String email, String password) async {
    if (_isSigningIn) return false;
    _isSigningIn = true;
    _errorMessage = null;
    notifyListeners();
    bool success = false;

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      success = true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthCodeToMessage(e.code);
    } catch (e) {
      _errorMessage = "An unexpected sign-in error occurred.";
    } finally {
      _isSigningIn = false;
      notifyListeners();
    }
    return success;
  }

  Future<bool> signUpWithEmailPassword(String email, String password) async {
    if (_isSigningIn) return false;
    _isSigningIn = true;
    _errorMessage = null;
    notifyListeners();
    bool success = false;

    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      success = true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthCodeToMessage(e.code);
    } catch (e) {
      _errorMessage = "An unexpected sign-up error occurred.";
    } finally {
      _isSigningIn = false;
      notifyListeners();
    }
    return success;
  }

  Future<void> reloadUser() async {
    if (_currentUser != null) {
      try {
        await _currentUser!.reload();
        _currentUser = _auth.currentUser;
        notifyListeners();
      } catch (e) {
         _errorMessage = "Failed to refresh user data. Please try again.";
         // Consider logging the original error: print("AuthProvider: Error reloading user: $e");
         notifyListeners();
      }
    }
  }

  String _mapAuthCodeToMessage(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid email or password. Please try again.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      default:
        return 'An authentication error occurred. Please try again.';
    }
  }
}