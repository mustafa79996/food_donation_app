import 'package:flutter/material.dart';

import 'welfare_login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Preferences',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('Enable notifications'),
            value: true,
            onChanged: (_) {},
          ),

          SwitchListTile(
            title: const Text('Show donation reminders'),
            value: false,
            onChanged: (_) {},
          ),

          const SizedBox(height: 24),

          // Welfare Centre
          const Text(
            'Welfare Centre',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Welfare Centre Login'),
            subtitle: const Text(
              'Login to manage food donations',
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const WelfareLoginScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          const Text(
            'About',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App version'),
            subtitle: const Text('1.0.0'),
          ),

          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy policy'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
