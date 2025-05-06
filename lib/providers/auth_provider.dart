import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

// Keep GoogleSignIn initialization for the sign-in flow itself
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email'],
  // TODO: Add your Web Client ID here for web support (if needed)
  clientId:
      "321771410537-6hljqq0mmtb85vthhullk6q73c3acj1c.apps.googleusercontent.com",
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
        } else {
          // print('AuthProvider: Google Sign-In cancelled by user.');
        }
      } else {
        // print('AuthProvider: Google Sign-In cancelled by user.');
      }
    } catch (error) {
      // print(
      //   "AuthProvider: Error during Google Sign-In or Firebase credential sign-in: $error",
      // );
      _errorMessage = "Google Sign-In failed: $error"; // Set error message
      // Consider showing a user-friendly error message
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
      // Also sign out from Google
      await _googleSignIn.signOut();
      // No need to manually set _currentUser to null, authStateChanges listener handles it
      // notifyListeners(); // Listener handles notification
    } catch (error) {
      // print("AuthProvider: Error signing out: $error");
      _errorMessage = "Sign out failed: $error"; // Set error message
      // Consider showing a user-friendly error message
    }
    notifyListeners(); // Notify listeners even on error (to update message)
  }

  // --- Placeholder methods for other auth types ---

  Future<bool> signInWithEmailPassword(String email, String password) async {
    if (_isSigningIn) return false;
    _isSigningIn = true;
    _errorMessage = null; // Clear previous error
    notifyListeners();
    bool success = false;

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Auth state listener will update _currentUser and notify
      success = true;
    } on FirebaseAuthException catch (e) {
      // print(
      //   'AuthProvider: Firebase Auth Error (Sign In): ${e.code} - ${e.message}',
      // );
      _errorMessage = _mapAuthCodeToMessage(e.code); // Set mapped message
      // TODO: Provide user feedback based on e.code (e.g., 'invalid-credential', 'user-disabled')
    } catch (e) {
      // print('AuthProvider: Generic Sign In Error: $e');
      _errorMessage = "An unexpected sign-in error occurred."; // Set generic message
      // TODO: Provide user feedback
    } finally {
      _isSigningIn = false;
      notifyListeners();
    }
    return success;
  }

  Future<bool> signUpWithEmailPassword(String email, String password) async {
    if (_isSigningIn) return false;
    _isSigningIn = true;
    _errorMessage = null; // Clear previous error
    notifyListeners();
    bool success = false;

    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Auth state listener will update _currentUser and notify
      success = true;
    } on FirebaseAuthException catch (e) {
      // print(
      //   'AuthProvider: Firebase Auth Error (Sign Up): ${e.code} - ${e.message}',
      // );
      _errorMessage = _mapAuthCodeToMessage(e.code); // Set mapped message
      // TODO: Provide user feedback based on e.code (e.g., 'weak-password', 'email-already-in-use')
    } catch (e) {
      // print('AuthProvider: Generic Sign Up Error: $e');
      _errorMessage = "An unexpected sign-up error occurred."; // Set generic message
      // TODO: Provide user feedback
    } finally {
      _isSigningIn = false;
      notifyListeners();
    }
    return success;
  }

  // Add method to reload user data and notify
  Future<void> reloadUser() async {
    if (_currentUser != null) {
      try {
        await _currentUser!.reload();
        // Re-assign _currentUser from the instance to get updated data
        _currentUser = _auth.currentUser; 
        notifyListeners();
      } catch (e) {
        // print("AuthProvider: Error reloading user: $e");
        // Handle reload error if needed, maybe set an error message
         _errorMessage = "Failed to refresh user data: $e";
         notifyListeners(); // Notify about the error
      }
    }
  }

  // Helper method to map Firebase Auth error codes to user-friendly messages
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
      // Add other common codes as needed
      default:
        return 'An authentication error occurred. Please try again.';
    }
  }

  // TODO: Add methods for Phone/OTP Auth using FirebaseAuth if implementing that flow
  // e.g., verifyPhoneNumber, signInWithPhoneNumberCredential
}
