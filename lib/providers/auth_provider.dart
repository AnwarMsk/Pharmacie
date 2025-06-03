import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email'],
  clientId: "449259807974-179fkrlkvpmhgedqfj53qb1a5l6dspsj.apps.googleusercontent.com",
);
class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  bool _isSigningIn = false;
  String? _errorMessage;
  User? get currentUser => _currentUser;
  bool get isSigningIn => _isSigningIn;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      if (_currentUser != null) {
      } else {
      }
      notifyListeners();
    });
  }
  Future<bool> signInWithGoogle() async {
    if (_isSigningIn) return false;
    _isSigningIn = true;
    _errorMessage = null;
    notifyListeners();
    bool success = false;
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );
        if (userCredential.user != null) {
          success = true;
        }
      } else {
        _errorMessage = "Google Sign-In was cancelled.";
      }
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_cancelled') {
        _errorMessage = "Google Sign-In was cancelled.";
      } else if (e.code == 'network_error') {
        _errorMessage = "A network error occurred during Google Sign-In. Please check your connection.";
      } else {
        _errorMessage = "Google Sign-In failed. Error: ${e.message ?? e.code}";
      }
    } catch (error, stackTrace) {
      _errorMessage = "An unexpected error occurred during Google Sign-In. Please try again.";
    } finally {
      _isSigningIn = false;
      notifyListeners();
    }
    return success;
  }
  Future<void> signOut() async {
    _errorMessage = null;
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (error) {
      _errorMessage = "Sign out failed. Please try again.";
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