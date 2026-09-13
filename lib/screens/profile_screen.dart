import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: const Color(0xFF1E7D45),
              child: Icon(Icons.person, size: 44, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'Guest Donor',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(user?.email ?? 'No email available', style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.history_outlined),
                title: const Text('Donation history'),
                subtitle: const Text('View submitted donations'),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.support_agent_outlined),
                title: const Text('Support'),
                subtitle: const Text('Help and feedback'),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => authProvider.signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
