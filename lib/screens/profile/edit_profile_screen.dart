import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dwaya_app/providers/auth_provider.dart';
import 'package:dwaya_app/utils/colors.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentDisplayName;

  const EditProfileScreen({super.key, required this.currentDisplayName});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentDisplayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveDisplayName() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final newName = _nameController.text.trim();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      // Should not happen, but good practice to check
      _showErrorSnackbar('Error: Not logged in.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await user.updateDisplayName(newName);
      // print('Display name updated successfully');
      // Optionally update provider state if necessary, but popping might be enough
      // authProvider.notifyListeners(); // If direct update needed
      if (mounted) {
        // Notify listeners *after* successful update and *before* popping
        context.read<AuthProvider>().notifyListeners();
        Navigator.of(context).pop(); // Go back to profile screen
      }
    } catch (e) {
      _showErrorSnackbar('Failed to update display name. Please try again.');
    } finally {
      // Ensure loading state is reset even if widget is disposed during async gap
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
        title: const Text('Edit Display Name'),
        backgroundColor: white,
        foregroundColor: black,
        elevation: 1,
        actions: [
          // Save Button
          TextButton(
            onPressed: _isLoading ? null : _saveDisplayName,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text(
                      'Save',
                      style: TextStyle(color: primaryGreen, fontSize: 16),
                    ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a display name';
                  }
                  return null;
                },
              ),
              // Add some spacing
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
