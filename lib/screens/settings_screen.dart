import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../utils/routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _remindersEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          _buildSectionHeader('Preferences'),
          const SizedBox(height: 10),
          _buildGroupContainer([
            SwitchListTile(
              title: const Text(
                'Enable notifications',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Receive alerts on donation pickups and status',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              activeThumbColor: AppTheme.primaryGreen,
              value: _notificationsEnabled,
              onChanged: (val) => setState(() => _notificationsEnabled = val),
            ),
            const Divider(height: 1, indent: 16, color: Color(0xFFF1F5F9)),
            SwitchListTile(
              title: const Text(
                'Show donation reminders',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Remind when food is near expiration date',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              activeThumbColor: AppTheme.primaryGreen,
              value: _remindersEnabled,
              onChanged: (val) => setState(() => _remindersEnabled = val),
            ),
          ]),
          const SizedBox(height: 24),

          _buildSectionHeader('Welfare Centre'),
          const SizedBox(height: 10),
          _buildGroupContainer([
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.business_outlined,
                  color: Color(0xFF15803D),
                  size: 22,
                ),
              ),
              title: const Text(
                'Welfare Centre Login',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Login or switch to welfare centre account',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
              ),
              onTap: () => Navigator.pushNamed(context, Routes.welfareLogin),
            ),
            const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.dashboard_outlined,
                  color: Color(0xFF15803D),
                  size: 22,
                ),
              ),
              title: const Text(
                'Welfare Dashboard',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'View and manage incoming surplus food donations',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
              ),
              onTap: () => Navigator.pushNamed(context, Routes.welfareDashboard),
            ),
            const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: Color(0xFF15803D),
                  size: 22,
                ),
              ),
              title: const Text(
                'Welfare Applications (Admin)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Accept or reject welfare centre registration requests',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
              ),
              onTap: () =>
                  Navigator.pushNamed(context, Routes.welfareVerification),
            ),
            const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_city_outlined,
                  color: Color(0xFF0284C7),
                  size: 22,
                ),
              ),
              title: const Text(
                'Nearby Welfare Centres',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Locate welfare centres and charities near you',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
              ),
              onTap: () =>
                  Navigator.pushNamed(context, Routes.nearestWelfareCenters),
            ),
          ]),
          const SizedBox(height: 24),

          _buildSectionHeader('About'),
          const SizedBox(height: 10),
          _buildGroupContainer([
            ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
              ),
              title: const Text(
                'App version',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('1.0.0 (FoodLink Modern)'),
            ),
            const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
            ListTile(
              leading: const Icon(
                Icons.privacy_tip_outlined,
                color: Color(0xFF64748B),
              ),
              title: const Text(
                'Privacy policy',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
              ),
              onTap: () {},
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildGroupContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}
