import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/admin_config.dart';
import '../utils/routes.dart';
import '../widgets/foodlink_ui_components.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isAdmin = isWelfareAdmin(user);

    final displayName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : 'Mohammed Mustafa';
    final email = user?.email?.isNotEmpty == true
        ? user!.email!
        : 'mustafa79996@gmail.com';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Purple Wave Banner
            ClipPath(
              clipper: SoftCurvedHeaderClipper(),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 10,
                  20,
                  40,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF8B5CF6), // Vibrant purple
                      Color(0xFFA78BFA), // Medium purple
                      Color(0xFFC4B5FD), // Soft lavender
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    // Top Row: Logo + Settings Icon
                    FoodLinkHeaderTopRow(
                      trailing: InkWell(
                        onTap: () =>
                            Navigator.pushNamed(context, Routes.settings),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.settings_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Centered Avatar with edit pencil badge
                    Stack(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: const BoxDecoration(
                            color: Color(0xFF5B4DDF), // Royal indigo/purple
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 52,
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E293B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Name
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Email
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Verified Welfare Administrator',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Column(
                children: [
                  // 3 Stat Badges Row (Donations, Accepted, Pending)
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('donations')
                        .snapshots(),
                    builder: (context, snapshot) {
                      int totalDonations = 0;
                      int acceptedCount = 0;
                      int pendingCount = 0;
                      int rejectedCount = 0;

                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        final docs = snapshot.data!.docs;
                        final userDocs = user != null
                            ? docs.where((d) {
                                final data = d.data();
                                return data['userId'] == user.uid ||
                                    data['donorId'] == user.uid ||
                                    (data['donorEmail'] != null &&
                                        data['donorEmail'] == user.email) ||
                                    data['donorName'] == displayName;
                              }).toList()
                            : docs;

                        totalDonations = userDocs.length;
                        acceptedCount = userDocs.where((d) {
                          final st = (d.data()['status'] as String? ?? '')
                              .toLowerCase();
                          return st == 'accepted' || st == 'approved';
                        }).length;
                        pendingCount = userDocs.where((d) {
                          final st = (d.data()['status'] as String? ?? '')
                              .toLowerCase();
                          return st == 'pending' || st == '';
                        }).length;
                        rejectedCount = userDocs.where((d) {
                          final st = (d.data()['status'] as String? ?? '')
                              .toLowerCase();
                          return st == 'rejected';
                        }).length;
                      }

                      return StatRow(
                        items: [
                          StatItemData(
                            label: 'Total',
                            value: '$totalDonations',
                            bgColor: const Color(0xFFF1F5F9),
                            textColor: const Color(0xFF1E293B),
                          ),
                          StatItemData(
                            label: 'Pending',
                            value: '$pendingCount',
                            bgColor: const Color(0xFFFFFBEB),
                            textColor: const Color(0xFFD97706),
                          ),
                          StatItemData(
                            label: 'Accepted',
                            value: '$acceptedCount',
                            bgColor: const Color(0xFFDCFCE7),
                            textColor: const Color(0xFF15803D),
                          ),
                          StatItemData(
                            label: 'Rejected',
                            value: '$rejectedCount',
                            bgColor: const Color(0xFFFEE2E2),
                            textColor: const Color(0xFFDC2626),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Menu Options Card List
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFF1F5F9),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Option 1: Donation history
                        _buildMenuTile(
                          icon: Icons.history_rounded,
                          iconBgColor: const Color(0xFFEDE9FE),
                          iconColor: const Color(0xFF5B4DDF),
                          title: 'Donation history',
                          subtitle: 'View your submitted donations',
                          onTap: () => Navigator.pushNamed(
                            context,
                            Routes.foodList,
                            arguments: {'myDonations': true},
                          ),
                        ),
                        const Divider(
                          height: 1,
                          indent: 68,
                          color: Color(0xFFF1F5F9),
                        ),

                        // Option 2: Support assistant
                        _buildMenuTile(
                          icon: Icons.headset_mic_rounded,
                          iconBgColor: const Color(0xFFEDE9FE),
                          iconColor: const Color(0xFF5B4DDF),
                          title: 'Support assistant (Mia)',
                          subtitle:
                              'Chat live with Mia, our support assistant',
                          onTap: () =>
                              Navigator.pushNamed(context, Routes.supportChat),
                        ),
                        const Divider(
                          height: 1,
                          indent: 68,
                          color: Color(0xFFF1F5F9),
                        ),

                        // Option 3: Account settings
                        _buildMenuTile(
                          icon: Icons.settings_rounded,
                          iconBgColor: const Color(0xFFEDE9FE),
                          iconColor: const Color(0xFF5B4DDF),
                          title: 'Account settings',
                          subtitle: 'Edit your profile details',
                          onTap: () =>
                              Navigator.pushNamed(context, Routes.settings),
                        ),
                        const Divider(
                          height: 1,
                          indent: 68,
                          color: Color(0xFFF1F5F9),
                        ),

                        // Nearby Welfare Centres
                        _buildMenuTile(
                          icon: Icons.location_city_outlined,
                          iconBgColor: const Color(0xFFE0F2FE),
                          iconColor: const Color(0xFF0284C7),
                          title: 'Nearby Welfare Centres',
                          subtitle: 'Locate welfare centres and charities',
                          onTap: () => Navigator.pushNamed(
                            context,
                            Routes.nearestWelfareCenters,
                          ),
                        ),
                        const Divider(
                          height: 1,
                          indent: 68,
                          color: Color(0xFFF1F5F9),
                        ),

                        // Admin Welfare Applications Option
                        _buildMenuTile(
                          icon: Icons.fact_check_outlined,
                          iconBgColor: const Color(0xFFE8F5E9),
                          iconColor: const Color(0xFF15803D),
                          title: 'Welfare Centre Applications (Admin)',
                          subtitle:
                              'Review and accept/reject centre registrations',
                          onTap: () => Navigator.pushNamed(
                            context,
                            Routes.welfareVerification,
                          ),
                        ),
                        const Divider(
                          height: 1,
                          indent: 68,
                          color: Color(0xFFF1F5F9),
                        ),

                        // Welfare Dashboard
                        _buildMenuTile(
                          icon: Icons.dashboard_outlined,
                          iconBgColor: const Color(0xFFE8F5E9),
                          iconColor: const Color(0xFF15803D),
                          title: 'Welfare Dashboard',
                          subtitle: 'Manage food donations and requests',
                          onTap: () => Navigator.pushNamed(
                            context,
                            Routes.welfareDashboard,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sign Out Button (Royal Purple)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => authProvider.signOut(),
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B4DDF), // Royal purple
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bottom Slogan Banner "Good Food Brighter Communities"
                  const GoodFoodCommunityCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12.5,
          color: Color(0xFF64748B),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF94A3B8),
        size: 22,
      ),
      onTap: onTap,
    );
  }
}
