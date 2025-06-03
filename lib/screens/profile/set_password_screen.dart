import 'package:dwaya_app/providers/auth_provider.dart';
import 'package:dwaya_app/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});
  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}
class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  Future<void> _setPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    final newPassword = _newPasswordController.text;
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null || user.email == null) {
      _showErrorSnackbar('Error: User not found or email missing.');
      setState(() {
        _isLoading = false;
      });
      return;
    }
    if (user.providerData.any((p) => p.providerId == 'password')) {
      _showErrorSnackbar(
        'Error: Password sign-in already enabled for this account.',
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: newPassword,
    );
    try {
      await user.linkWithCredential(credential);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Password set successfully! You can now sign in with email/password.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to set password. Please try again.';
      if (e.code == 'weak-password') {
        errorMessage = 'The password is too weak.';
      } else if (e.code == 'credential-already-in-use') {
        errorMessage =
            'This email/password combination is already linked to another account.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage =
            'The email address is already in use by another account.';
      } else if (e.code == 'requires-recent-login') {
        errorMessage =
            'This action requires a recent login. Please log out and log back in.';
      } else if (e.code == 'provider-already-linked') {
        errorMessage = 'This email/password combination is already linked to another account.';
      }
      if (mounted) _showErrorSnackbar(errorMessage);
    } catch (e) {
      if (mounted)
        _showErrorSnackbar('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Account Password'),
        backgroundColor: white,
        foregroundColor: black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Choose a password to enable email/password sign-in for your account.',
                style: TextStyle(color: darkGrey),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_isNewPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isNewPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed:
                        () => setState(() {
                          _isNewPasswordVisible = !_isNewPasswordVisible;
                        }),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter a password';
                  if (value.length < 6)
                    return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed:
                        () => setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        }),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please confirm your password';
                  if (value != _newPasswordController.text)
                    return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _setPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(white),
                          ),
                        )
                        : const Text(
                          'Set Password',
                          style: TextStyle(fontSize: 18),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}