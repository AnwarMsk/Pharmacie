import 'package:dwaya_app/screens/auth/sign_up_screen.dart';
import 'package:dwaya_app/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:dwaya_app/utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:dwaya_app/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

/// Screen for user authentication with email/password and Google sign-in
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles email/password sign in
  Future<void> _signInWithEmailPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isSigningIn) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    try {
      final success = await authProvider.signInWithEmailPassword(
        email,
        password,
      );
      if (success) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        if (mounted) _showErrorSnackbar(authProvider.errorMessage ?? 'Login failed. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showErrorSnackbar(authProvider.errorMessage ?? 'An authentication error occurred.');
    } catch (e) {
      if (mounted)
        _showErrorSnackbar(authProvider.errorMessage ?? 'An unexpected error occurred. Please try again.');
    }
  }

  /// Shows error message in a snackbar
  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  /// Shows success message in a snackbar
  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  /// Handles Google sign in
  Future<void> _signInWithGoogle(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    bool success = await authProvider.signInWithGoogle();
    if (success && mounted) {
      _navigateToHome();
    } else if (!success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Sign-in failed. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// Navigates to sign up screen
  void _navigateToSignUp() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SignUpScreen()));
  }

  /// Handles password reset flow
  Future<void> _forgotPassword() async {
    final emailController = TextEditingController();
    bool? emailSent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we will send you a link to reset your password.',
            ),
            const SizedBox(height: 15),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Send Email'),
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty && RegExp(r"^\S+@\S+\.\S+$").hasMatch(email)) {
                Navigator.of(context).pop(true);
              }
            },
          ),
        ],
      ),
    );
    emailController.dispose();
    if (emailSent == true) {
      final email = emailController.text.trim();
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        if (mounted) {
          _showSuccessSnackbar('Password reset email sent to $email. Please check your inbox.');
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = _mapAuthCodeToMessage(e.code);
        if (mounted) {
          _showErrorSnackbar(errorMessage);
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackbar('An unexpected error occurred. Please try again.');
        }
      }
    }
  }

  /// Navigates to home screen
  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  /// Maps Firebase auth error codes to user-friendly messages
  String _mapAuthCodeToMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No user found for that email.';
      default:
        return 'An error occurred sending the reset email.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isSigningIn = authProvider.isSigningIn;
    return Scaffold(
      backgroundColor: white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 30.0,
              vertical: 20.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/images/logo.png', height: 100),
                  const SizedBox(height: 8),
                  const Text(
                    'Welcome Back!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Login to your account',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: darkGrey),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter your email';
                      if (!RegExp(r"^\S+@\S+\.\S+$").hasMatch(value))
                        return 'Please enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter your password';
                      return null;
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      child: const Text('Forgot Password?'),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed:
                        authProvider.isSigningIn
                            ? null
                            : _signInWithEmailPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: white,
                      minimumSize: const Size(double.infinity, 50),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child:
                        authProvider.isSigningIn
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  white,
                                ),
                              ),
                            )
                            : const Text(
                              'Login',
                              style: TextStyle(fontSize: 18),
                            ),
                  ),
                  const SizedBox(height: 25),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('OR', style: TextStyle(color: darkGrey)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                    onPressed:
                        isSigningIn ? null : () => _signInWithGoogle(context),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: black,
                      backgroundColor: white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: mediumGrey),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    icon: isSigningIn
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.redAccent,
                                ),
                              ),
                            )
                            : const FaIcon(
                              FontAwesomeIcons.google,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                    label: Text(
                      isSigningIn ? 'Signing In...' : 'Continue with Google',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(color: darkGrey),
                      ),
                      TextButton(
                        onPressed: _navigateToSignUp,
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}