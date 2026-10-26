import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/admin_config.dart';
import '../utils/routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isAdmin = isWelfareAdmin(user);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: const Color(0xFF1E7D45),
              child: const Icon(Icons.person, size: 44, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName?.isNotEmpty == true
                  ? user!.displayName!
                  : (isAdmin ? 'Administrator' : 'Community Member'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? 'No email available',
              style: const TextStyle(color: Colors.black54),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E7D45)),
                ),
                child: const Text(
                  'Verified Welfare Administrator',
                  style: TextStyle(
                    color: Color(0xFF1E7D45),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (isAdmin) ...[
              Card(
                elevation: 2,
                color: Colors.green.shade50,
                child: ListTile(
                  leading: const Icon(Icons.fact_check_outlined, color: Color(0xFF1E7D45)),
                  title: const Text(
                    'Welfare Applications (Admin)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Review and Accept/Reject welfare centre registrations',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.pushNamed(context, Routes.welfareVerification),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.dashboard_outlined, color: Color(0xFF1E7D45)),
                  title: const Text(
                    'Welfare Dashboard',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('View and manage pending food donations'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.pushNamed(context, Routes.welfareDashboard),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_city_outlined),
                title: const Text('Nearby Welfare Centres'),
                subtitle: const Text('Locate welfare centres and charities'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.pushNamed(context, Routes.nearestWelfareCenters),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.support_agent_outlined),
                title: const Text('Support'),
                subtitle: const Text('Chat with the FoodLink help assistant'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, Routes.supportChat),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => authProvider.signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
