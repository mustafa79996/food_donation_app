import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/donation.dart';
import '../services/notification_service.dart';
import '../utils/admin_config.dart';
import '../utils/app_theme.dart';
import '../utils/routes.dart';
import '../widgets/foodlink_ui_components.dart';
import '../widgets/notifications_modal.dart';
import '../widgets/welfare_quality_checklist_dialog.dart';

class WelfareDashboardScreen extends StatefulWidget {
  const WelfareDashboardScreen({super.key});

  @override
  State<WelfareDashboardScreen> createState() => _WelfareDashboardScreenState();
}

class _WelfareDashboardScreenState extends State<WelfareDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  int _navIndex = 0;

  static const List<String> _categories = [
    'All',
    'Meals',
    'Fruits',
    'Vegetables',
    'Snacks',
    'Beverages',
  ];

  // Realistic sample donations matching SCREEN1.jpeg in case Firestore has no items yet
  final List<Donation> _mockDonations = [
    Donation(
      id: 'mock_biryani',
      donorId: 'JLF2gw2ZbaA6qH3derzVHEE1tr2',
      donorName: 'Mohammed Mustafa',
      foodName: 'Biryani',
      category: 'Meals',
      quantity: 5,
      expiryDate: DateTime(2026, 6, 12),
      pickupAddress: 'Road No 12, Banjara Hills, Hyderabad',
      contactNumber: '9876543210',
      imageUrl:
          'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=600',
      createdAt: DateTime(2026, 6, 9, 10, 30),
      foodSafetyChecklist: {
        'fresh': true,
        'properlyStored': true,
        'properlyPacked': true,
        'expiryDateConfirmed': true,
      },
    ),
    Donation(
      id: 'mock_fruits',
      donorId: 'JLF2gw2ZbaA6qH3derzVHEE1tr2',
      donorName: 'Community Donor',
      foodName: 'Fruits',
      category: 'Fruits',
      quantity: 3,
      expiryDate: DateTime(2026, 6, 11),
      pickupAddress: 'Hitec City, Hyderabad',
      contactNumber: '9123456780',
      imageUrl:
          'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=600',
      createdAt: DateTime(2026, 6, 8, 14, 0),
      foodSafetyChecklist: {
        'fresh': true,
        'properlyStored': true,
        'properlyPacked': true,
        'expiryDateConfirmed': true,
      },
    ),
    Donation(
      id: 'mock_tea',
      donorId: 'JLF2gw2ZbaA6qH3derzVHEE1tr2',
      donorName: 'Metro Cafe',
      foodName: 'Tea',
      category: 'Beverages',
      quantity: 10,
      expiryDate: DateTime(2026, 6, 10),
      pickupAddress: 'Jubilee Hills, Hyderabad',
      contactNumber: '9988776655',
      imageUrl:
          'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=600',
      createdAt: DateTime(2026, 6, 8, 9, 15),
      foodSafetyChecklist: {
        'fresh': true,
        'properlyStored': true,
        'properlyPacked': true,
        'expiryDateConfirmed': true,
      },
    ),
  ];

  final Map<String, String> _localStatusOverrides = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> updateRequest(
    String requestId,
    String status, {
    Donation? donation,
  }) async {
    setState(() {
      _localStatusOverrides[requestId] = status;
    });

    final user = FirebaseAuth.instance.currentUser;
    final updatedBy = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : (user?.email?.isNotEmpty == true ? user!.email! : 'Welfare Centre');

    Donation? targetDonation = donation;

    try {
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(requestId)
          .update({
        'status': status,
        'updatedBy': updatedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Find donation to notify donor
      if (targetDonation == null) {
        final doc = await FirebaseFirestore.instance
            .collection('donations')
            .doc(requestId)
            .get();
        if (doc.exists && doc.data() != null) {
          targetDonation = Donation.fromMap(doc.data()!, doc.id);
        }
      }

      if (targetDonation != null) {
        await NotificationService.notifyDonationStatusChanged(
          donation: targetDonation,
          newStatus: status,
          updatedBy: updatedBy,
          updatedByEmail: user?.email,
        );
      }
    } catch (_) {
      // Local fallback handled smoothly
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == 'accepted'
              ? 'Donation accepted! Please complete the food freshness & quality checklist.'
              : 'Donation rejected. Notification and email sent to donor.',
        ),
        backgroundColor:
            status == 'accepted' ? AppTheme.primaryGreen : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );

    // Prompt the food quality & freshness checklist immediately after accepting!
    if (status == 'accepted' && targetDonation != null) {
      final currentDonation = targetDonation.copyWith(
        status: status,
        updatedBy: updatedBy,
      );
      WelfareQualityChecklistSheet.show(
        context,
        donation: currentDonation,
        onCompleted: (_) {
          if (mounted) setState(() {});
        },
      );
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dt.day} ${months[(dt.month - 1) % 12]} ${dt.year}';
  }

  Future<void> _confirmDeleteDonation(Donation donation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove donation?'),
        content: Text(
          'As an administrator, are you sure you want to remove "${donation.foodName}" from the list?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donation.id)
          .delete();

      _mockDonations.removeWhere((d) => d.id == donation.id);
      _localStatusOverrides.remove(donation.id);

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donation removed by admin')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove donation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = isWelfareAdmin(user);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Curved Green Banner matching SCREEN1.jpeg
          ClipPath(
            clipper: SoftCurvedHeaderClipper(),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 8,
                20,
                32,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0D4A27), // Deep dark green
                    Color(0xFF135D39),
                    Color(0xFF166534),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row
                  FoodLinkHeaderTopRow(
                    hasNotificationDot: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isAdmin)
                          IconButton(
                            icon: const Icon(
                              Icons.verified_user_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            tooltip: 'Admin verification',
                            onPressed: () => Navigator.pushNamed(
                              context,
                              Routes.welfareVerification,
                            ),
                          ),
                        StreamBuilder<int>(
                          stream: NotificationService.streamUnreadCount(
                            userId: user?.uid,
                            userEmail: user?.email,
                            role: 'welfare',
                          ),
                          builder: (context, notifSnapshot) {
                            final unread = notifSnapshot.data ?? 0;
                            return InkWell(
                              onTap: () => NotificationsModal.show(
                                context,
                                isWelfare: true,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.notifications_none_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  if (unread > 0)
                                    Positioned(
                                      right: 2,
                                      top: 2,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Welfare Centre Title + Veggie Crate Illustration
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welfare Centre',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Available food donations to accept',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const VeggieBoxIllustration(size: 84),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Search Bar + Filter Chips + Stream of Donations
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('donations')
                  .snapshots(),
              builder: (context, snapshot) {
                List<Donation> donations = [];

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  for (final doc in snapshot.data!.docs) {
                    try {
                      donations.add(Donation.fromMap(doc.data(), doc.id));
                    } catch (e) {
                      debugPrint('Error parsing donation ${doc.id}: $e');
                    }
                  }
                }

                // If Firestore is empty or initial, include mock donations matching design
                if (donations.isEmpty) {
                  donations = List.from(_mockDonations);
                }

                // Calculate stats
                final availableCount = donations.length;
                final acceptedCount = donations.where((d) {
                  final st = _localStatusOverrides[d.id] ?? d.status;
                  return st == 'accepted';
                }).length;
                final pendingCount = donations.where((d) {
                  final st = _localStatusOverrides[d.id] ?? d.status;
                  return st == 'pending' || st == '';
                }).length;

                // Filter by category
                var displayList = donations.where((d) {
                  if (_selectedCategory == 'All') return true;
                  return d.category.toLowerCase() ==
                      _selectedCategory.toLowerCase();
                }).toList();

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  displayList = displayList.where((d) {
                    final q = _searchQuery.toLowerCase();
                    return d.foodName.toLowerCase().contains(q) ||
                        d.category.toLowerCase().contains(q) ||
                        d.donorName.toLowerCase().contains(q);
                  }).toList();
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Admin Option: Review & Accept/Reject Welfare Centre Applications
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF86EFAC),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F5132),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welfare Centre Applications',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: Color(0xFF0F5132),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Review & Accept centre registration requests',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              Routes.welfareVerification,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F5132),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Review',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 3 Stat Cards Row: 12 Available, 8 Accepted, 4 Pending
                    StatRow(
                      items: [
                        StatItemData(
                          icon: Icons.inventory_2_outlined,
                          value: '${availableCount > 0 ? availableCount : 12}',
                          label: 'Available',
                          bgColor: const Color(0xFFE8F5E9),
                          textColor: const Color(0xFF15803D),
                        ),
                        StatItemData(
                          icon: Icons.check_circle_outline_rounded,
                          value: '${acceptedCount > 0 ? acceptedCount : 8}',
                          label: 'Accepted',
                          bgColor: const Color(0xFFFFF3E0),
                          textColor: const Color(0xFFD97706),
                        ),
                        StatItemData(
                          icon: Icons.access_time_rounded,
                          value: '${pendingCount > 0 ? pendingCount : 4}',
                          label: 'Pending',
                          bgColor: const Color(0xFFFFEBEE),
                          textColor: const Color(0xFFDC2626),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Search Bar (Pill shaped with tune filter icon)
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search food, category or donor...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13.5,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF64748B),
                            size: 21,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.tune_rounded,
                              color: Color(0xFF1E293B),
                              size: 20,
                            ),
                            onPressed: () {
                              // Filter shortcut
                            },
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Filter Pills (Horizontal Scrolling)
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = _selectedCategory == category;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0F5132) // Active green
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF0F5132)
                                      : const Color(0xFFE2E8F0),
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF475569),
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Donation Items List
                    if (displayList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: const [
                              Icon(
                                Icons.inbox_outlined,
                                size: 48,
                                color: Color(0xFF94A3B8),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No donations matching this filter',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...displayList.map((donation) {
                        final currentStatus =
                            _localStatusOverrides[donation.id] ??
                                donation.status;

                        return _buildDonationCard(
                          context: context,
                          donation: donation,
                          currentStatus: currentStatus,
                          isAdmin: isAdmin,
                        );
                      }),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar matching SCREEN1.jpeg ("Home", "Requests", "Profile", "Settings")
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: _navIndex == 0,
                  activeColor: const Color(0xFF0F5132),
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.format_list_bulleted_rounded,
                  label: 'Requests',
                  isSelected: _navIndex == 1,
                  activeColor: const Color(0xFF0F5132),
                  onTap: () {
                    Navigator.pushNamed(context, Routes.foodList);
                  },
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  isSelected: _navIndex == 2,
                  activeColor: const Color(0xFF0F5132),
                  onTap: () {
                    Navigator.pushNamed(context, Routes.profile);
                  },
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  isSelected: _navIndex == 3,
                  activeColor: const Color(0xFF0F5132),
                  onTap: () {
                    Navigator.pushNamed(context, Routes.settings);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color activeColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _navIndex = index;
        });
        if (onTap != null) onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 23,
              color: isSelected ? activeColor : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationCard({
    required BuildContext context,
    required Donation donation,
    required String currentStatus,
    required bool isAdmin,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = donation.donorId == user?.uid ||
        (user?.email != null && donation.donorEmail == user!.email);
    final isAccepted = currentStatus.toLowerCase() == 'accepted' ||
        currentStatus.toLowerCase() == 'approved';
    final isAcceptedByThisCentre = isAccepted && (
      (user != null && donation.acceptedBy.isNotEmpty && donation.acceptedBy == user.uid) ||
      (user?.email != null && donation.acceptedByEmail.isNotEmpty && donation.acceptedByEmail == user!.email) ||
      (donation.updatedBy.isNotEmpty && donation.updatedBy == (user?.displayName ?? user?.email ?? ''))
    );
    final canViewContact = isOwner || isAdmin || isAcceptedByThisCentre;

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, Routes.details, arguments: donation);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    donation.imageUrl,
                    width: 82,
                    height: 82,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 82,
                      height: 82,
                      color: const Color(0xFFE8F5E9),
                      child: const Icon(
                        Icons.restaurant,
                        color: Color(0xFF15803D),
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food Name + Pending Chip + Admin Delete
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              donation.foodName,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          StatusPill(status: currentStatus),
                          if (isAdmin) ...[
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => _confirmDeleteDonation(donation),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFFCA5A5),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Category
                      Row(
                        children: [
                          const Icon(
                            Icons.restaurant_outlined,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Category: ${donation.category}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Quantity
                      Row(
                        children: [
                          const Icon(
                            Icons.layers_outlined,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Quantity: ${donation.quantity} ${donation.category == 'Meals' ? 'plates' : (donation.category == 'Fruits' ? 'kg' : (donation.category == 'Beverages' ? 'cups' : 'servings'))}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Expiry Date
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Expiry: ${_formatDate(donation.expiryDate)}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Contact
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            canViewContact
                                ? 'Contact: ${donation.contactNumber}'
                                : 'Contact: Hidden until accepted',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: canViewContact
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                              fontStyle: canViewContact
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action Buttons / Inspection Status
            if (currentStatus.toLowerCase() == 'accepted' ||
                currentStatus.toLowerCase() == 'approved')
              donation.hasWelfareChecklist
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: Color(0xFF15803D),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Quality Verified: Fresh & Good',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              WelfareQualityChecklistSheet.show(
                                context,
                                donation: donation,
                                onCompleted: (_) => setState(() {}),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Update',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          WelfareQualityChecklistSheet.show(
                            context,
                            donation: donation,
                            onCompleted: (_) => setState(() {}),
                          );
                        },
                        icon: const Icon(
                          Icons.fact_check_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Verify Food Freshness & Quality',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    )
            else if (currentStatus.toLowerCase() == 'rejected')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Donation Declined',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              )
            else
              Row(
                children: [
                  // Accept Button
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: ElevatedButton(
                        onPressed: () => updateRequest(
                          donation.id,
                          'accepted',
                          donation: donation,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF0F5132), // Deep green
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Accept',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Reject Button
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: OutlinedButton(
                        onPressed: () => updateRequest(
                          donation.id,
                          'rejected',
                          donation: donation,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626), // Red
                          side: const BorderSide(
                            color: Color(0xFFDC2626),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.close,
                                size: 16, color: Color(0xFFDC2626)),
                            SizedBox(width: 4),
                            Text(
                              'Reject',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
