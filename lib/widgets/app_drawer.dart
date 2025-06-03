import 'package:flutter/material.dart';
import 'package:dwaya_app/utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:dwaya_app/providers/auth_provider.dart';
import 'package:dwaya_app/screens/auth/login_screen.dart';

/// A navigation drawer widget that provides access to app features and user account
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  /// Handles the logout process and navigates to login screen
  Future<void> _handleLogout(BuildContext context) async {
    await context.read<AuthProvider>().signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(color: primaryGreen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 60,
                ),
                const SizedBox(height: 10),
                const Text(
                  'DOUAYA',
                  style: TextStyle(color: white, fontSize: 20),
                ),
                Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    return Text(
                      auth.currentUser?.email ?? 'Quick pharmacy access',
                      style: const TextStyle(color: white, fontSize: 14),
                    );
                  },
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined, color: darkGrey),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: darkGrey),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: darkGrey),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: darkGrey),
            title: const Text('Logout'),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }
}