import 'package:dwaya_app/providers/auth_provider.dart';
import 'package:dwaya_app/screens/auth/login_screen.dart';
import 'package:dwaya_app/screens/profile/edit_profile_screen.dart';
import 'package:dwaya_app/screens/profile/change_password_screen.dart';
import 'package:dwaya_app/screens/profile/set_password_screen.dart';
import 'package:dwaya_app/screens/profile/update_email_screen.dart';
import 'package:dwaya_app/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (user != null) ...[
              ListTile(
                leading: const Icon(Icons.email_outlined, color: darkGrey),
                title: const Text('Email'),
                subtitle: Text(user.email ?? 'No email available'),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: darkGrey,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const UpdateEmailScreen(),
                      ),
                    );
                  },
                ),
              ),
              if (user.displayName != null && user.displayName!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.person_outline, color: darkGrey),
                  title: const Text('Display Name'),
                  subtitle: Text(user.displayName!),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: darkGrey,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => EditProfileScreen(
                                currentDisplayName: user.displayName!,
                              ),
                        ),
                      );
                    },
                  ),
                ),
              if (user.displayName == null || user.displayName!.isEmpty)
                ListTile(
                  leading: const Icon(
                    Icons.person_add_alt_1_outlined,
                    color: darkGrey,
                  ),
                  title: const Text('Add Display Name'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => const EditProfileScreen(
                              currentDisplayName: '',
                            ),
                      ),
                    );
                  },
                ),
              const Divider(height: 30),
              const Text(
                'Account Management',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: darkGrey,
                ),
              ),
              const SizedBox(height: 10),
              _buildPasswordManagementTile(context, user),
              ListTile(
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: Colors.redAccent[700],
                ),
                title: Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.redAccent[700]),
                ),
                onTap: () => _showDeleteConfirmationDialog(context, user),
              ),
              _buildLinkedAccountsSection(context, user),
            ] else
              const Text(
                'Not logged in',
              ),
            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                onPressed: () => _handleLogout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.redAccent,
                  foregroundColor: white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  Widget _buildPasswordManagementTile(BuildContext context, User user) {
    final providers = user.providerData.map((p) => p.providerId).toList();
    bool hasPassword = providers.contains('password');
    bool hasGoogle = providers.contains('google.com');
    bool hasVerifiedEmail =
        user.emailVerified || hasGoogle;
    if (hasPassword) {
      return ListTile(
        leading: const Icon(Icons.lock_outline, color: darkGrey),
        title: const Text('Change Password'),
        trailing: const Icon(Icons.chevron_right, color: darkGrey),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
          );
        },
      );
    } else if (hasVerifiedEmail) {
      return ListTile(
        leading: const Icon(Icons.lock_reset_outlined, color: darkGrey),
        title: const Text('Set Account Password'),
        subtitle: const Text('Add password sign-in for this account'),
        trailing: const Icon(Icons.chevron_right, color: darkGrey),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SetPasswordScreen()));
        },
      );
    }
    return const SizedBox.shrink();
  }
  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    User user,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account?'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('This action is permanent and cannot be undone.'),
                Text('Are you sure you want to delete your account?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent[700],
              ),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _handleDeleteAccount(context, user);
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> _handleDeleteAccount(BuildContext context, User user) async {
    bool requiresPassword = user.providerData.any(
      (p) => p.providerId == 'password',
    );
    String? password;
    try {
      if (requiresPassword) {
        password = await _promptForPassword(context);
        if (password == null) return;
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }
      await user.delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        await context.read<AuthProvider>().signOut();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to delete account. Please try again.';
      if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password. Account not deleted.';
      } else if (e.code == 'requires-recent-login') {
        errorMessage =
            'This action requires a recent login. Please log out and log back in to delete your account.';
      }
      if (context.mounted) _showErrorSnackbar(context, errorMessage);
    } catch (e) {
      if (context.mounted)
        _showErrorSnackbar(context, 'An unexpected error occurred.');
    }
  }
  Future<String?> _promptForPassword(BuildContext context) async {
    String? password;
    final passwordController = TextEditingController();
    await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Enter Password to Confirm'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: "Password"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                password = passwordController.text;
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
    passwordController.dispose();
    return password;
  }
  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }
  Widget _buildLinkedAccountsSection(BuildContext context, User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 30),
        const Text(
          'Sign-in Methods',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: darkGrey,
          ),
        ),
        const SizedBox(height: 10),
        if (user.providerData.isNotEmpty)
          ...user.providerData.map((providerInfo) {
            IconData iconData = Icons.link;
            String providerName = providerInfo.providerId;
            if (providerInfo.providerId == 'password') {
              iconData = Icons.email_outlined;
              providerName = 'Email/Password';
            } else if (providerInfo.providerId == 'google.com') {
              iconData = FontAwesomeIcons.google;
              providerName = 'Google';
            }
            return ListTile(
              leading: Icon(
                iconData,
                color: darkGrey,
                size: 20,
              ),
              title: Text(providerName),
            );
          }),
        if (user.providerData.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('No sign-in methods linked.'),
          ),
      ],
    );
  }
}