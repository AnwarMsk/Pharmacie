import 'package:dwaya_app/providers/auth_provider.dart';
import 'package:dwaya_app/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
class UpdateEmailScreen extends StatefulWidget {
  const UpdateEmailScreen({super.key});
  @override
  State<UpdateEmailScreen> createState() => _UpdateEmailScreenState();
}
class _UpdateEmailScreenState extends State<UpdateEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController();
  bool _isLoading = false;
  bool _requiresPassword = false;
  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _requiresPassword =
        user?.providerData.any((p) => p.providerId == 'password') ?? false;
  }
  @override
  void dispose() {
    _newEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  Future<void> _updateEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    final newEmail = _newEmailController.text.trim();
    final password = _passwordController.text;
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null || user.email == null) {
      _showErrorSnackbar('Error: User not found or email missing.');
      setState(() {
        _isLoading = false;
      });
      return;
    }
    try {
      if (user.email != null && password.isNotEmpty) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }
      await user.verifyBeforeUpdateEmail(newEmail);
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Verification Email Sent'),
                content: Text(
                  'A verification link has been sent to $newEmail. Please check your email and click the link to complete the update.',
                ),
                actions: [
                  TextButton(
                    child: const Text('OK'),
                    onPressed:
                        () => Navigator.of(context).pop(),
                  ),
                ],
              ),
        ).then((_) {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to update email. Please try again.';
      if (e.code == 'email-already-in-use') {
        errorMessage =
            'This email address is already in use by another account.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The new email address is not valid.';
      } else if (e.code == 'requires-recent-login') {
        errorMessage =
            'This action requires a recent login. Please log out and log back in.';
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
        title: const Text('Update Email'),
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
              Text(
                'Enter your new email address.${_requiresPassword ? " You'll also need to enter your current password." : ""}',
                style: const TextStyle(color: darkGrey),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _newEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'New Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'Please enter the new email address';
                  if (!RegExp(r"^\S+@\S+\.\S+$").hasMatch(value.trim()))
                    return 'Please enter a valid email address';
                  if (value.trim() ==
                      context.read<AuthProvider>().currentUser?.email) {
                    return 'This is already your current email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              if (_requiresPassword)
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (_requiresPassword && (value == null || value.isEmpty)) {
                      return 'Please enter your current password to verify';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateEmail,
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
                          'Send Verification Email',
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