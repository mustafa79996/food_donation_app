import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/donation.dart';
import '../providers/donation_provider.dart';
import '../services/notification_service.dart';
import '../utils/admin_config.dart';
import '../utils/app_theme.dart';
import '../utils/routes.dart';
import '../utils/voice_input.dart';
import '../widgets/foodlink_ui_components.dart';
import '../widgets/notifications_modal.dart';

class FoodListScreen extends StatefulWidget {
  final bool initialMyDonations;

  const FoodListScreen({super.key, this.initialMyDonations = false});

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      final myDonationsOnly = widget.initialMyDonations ||
          (args is Map && args['myDonations'] == true);
      if (myDonationsOnly) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<DonationProvider>().selectScope('My Donations');
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final donationProvider = context.watch<DonationProvider>();
    final donations = donationProvider.filteredDonations;
    final isMyHistory = donationProvider.selectedScope == 'My Donations';
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isMyHistory ? 'Donation History' : 'Available Donations',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF1E293B)),
            tooltip: 'Search donations',
            onPressed: () => showSearch(
              context: context,
              delegate: DonationSearchDelegate(donationProvider),
            ),
          ),
          StreamBuilder<int>(
            stream: NotificationService.streamUnreadCount(
              userId: user?.uid,
              userEmail: user?.email,
              role: 'donor',
            ),
            builder: (context, snapshot) {
              final unread = snapshot.data ?? 0;
              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFF1E293B),
                    ),
                    if (unread > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: 'Notifications',
                onPressed: () => NotificationsModal.show(context),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scope Selector: "My Donation History" vs "All Community Donations"
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () =>
                          donationProvider.selectScope('My Donations'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isMyHistory
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isMyHistory
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 16,
                              color: isMyHistory
                                  ? const Color(0xFF0F5132)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'My History',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isMyHistory
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isMyHistory
                                    ? const Color(0xFF0F5132)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => donationProvider.selectScope('All'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !isMyHistory
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: !isMyHistory
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.public_rounded,
                              size: 16,
                              color: !isMyHistory
                                  ? const Color(0xFF0F5132)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'All Donations',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: !isMyHistory
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: !isMyHistory
                                    ? const Color(0xFF0F5132)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Status Filter Chips (All, Pending, Accepted, Rejected)
            StatusFilterChips(
              selectedStatus: donationProvider.selectedStatus,
              allCount: donationProvider.totalCount,
              pendingCount: donationProvider.pendingCount,
              acceptedCount: donationProvider.acceptedCount,
              rejectedCount: donationProvider.rejectedCount,
              onSelected: donationProvider.selectStatus,
            ),
            const SizedBox(height: 8),

            // Category Chips (Meals, Fruits, etc.)
            CategoryChips(
              selectedCategory: donationProvider.selectedCategory,
              onSelected: donationProvider.selectCategory,
            ),
            const SizedBox(height: 12),

            // Donations List
            Expanded(
              child: donationProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : donationProvider.errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.orange,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  donationProvider.errorMessage!,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : donations.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 64,
                                      color: Colors.green.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      isMyHistory
                                          ? 'No donations in history'
                                          : 'No donations found',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isMyHistory
                                          ? 'Any donation you post will be listed here with its status (Pending, Accepted, or Rejected).'
                                          : 'Be the first to donate food to help local welfare centres!',
                                      style:
                                          const TextStyle(color: Colors.black54),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          Routes.donate,
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.volunteer_activism,
                                      ),
                                      label: const Text('Donate Food Now'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppTheme.primaryGreen,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                donationProvider.updateSearchQuery(
                                  donationProvider.searchQuery,
                                );
                              },
                              child: ListView.builder(
                                itemCount: donations.length,
                                itemBuilder: (context, index) {
                                  final donation = donations[index];
                                  return DonationCard(donation: donation);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusFilterChips extends StatelessWidget {
  final String selectedStatus;
  final int allCount;
  final int pendingCount;
  final int acceptedCount;
  final int rejectedCount;
  final ValueChanged<String> onSelected;

  const StatusFilterChips({
    super.key,
    required this.selectedStatus,
    required this.allCount,
    required this.pendingCount,
    required this.acceptedCount,
    required this.rejectedCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      {
        'label': 'All',
        'value': 'All',
        'count': allCount,
        'color': const Color(0xFF0F5132),
      },
      {
        'label': 'Pending',
        'value': 'pending',
        'count': pendingCount,
        'color': const Color(0xFFD97706),
      },
      {
        'label': 'Accepted',
        'value': 'accepted',
        'count': acceptedCount,
        'color': const Color(0xFF15803D),
      },
      {
        'label': 'Rejected',
        'value': 'rejected',
        'count': rejectedCount,
        'color': const Color(0xFFDC2626),
      },
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          final val = item['value'] as String;
          final isSelected = val == selectedStatus;
          final color = item['color'] as Color;
          final count = item['count'] as int;

          return InkWell(
            onTap: () => onSelected(val),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? color : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                      fontSize: 12.5,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.25)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color:
                            isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CategoryChips extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const CategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const categories = [
      'All',
      'Meals',
      'Fruits',
      'Vegetables',
      'Grains',
      'Snacks',
      'Beverages',
      'Other',
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;
          return InkWell(
            onTap: () => onSelected(category),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F5132) : Colors.white,
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
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                  fontSize: 12.5,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DonationCard extends StatelessWidget {
  final Donation donation;

  const DonationCard({super.key, required this.donation});

  Future<void> _deleteDonation(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = isWelfareAdmin(user);
    final isOwner = donation.donorId == user?.uid ||
        (user?.email != null && donation.donorEmail == user!.email);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdmin && !isOwner
            ? 'Remove donation (Admin)?'
            : 'Delete donation?'),
        content: Text(
          isAdmin && !isOwner
              ? 'As an administrator, are you sure you want to remove "${donation.foodName}" from the public list?'
              : 'Are you sure you want to delete this donation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              isAdmin && !isOwner ? 'Remove' : 'Delete',
              style: const TextStyle(
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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAdmin && !isOwner
                ? 'Donation removed by admin'
                : 'Donation deleted'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete donation: $e')),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = donation.donorId == user?.uid ||
        (user?.email != null && donation.donorEmail == user!.email);
    final isAdmin = isWelfareAdmin(user);
    final canDelete = isOwner || isAdmin;
    final isAccepted = donation.status.toLowerCase() == 'accepted' ||
        donation.status.toLowerCase() == 'approved';
    final isRejected = donation.status.toLowerCase() == 'rejected';

    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        Routes.details,
        arguments: donation,
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAccepted
                ? const Color(0xFFBBF7D0)
                : isRejected
                    ? const Color(0xFFFECACA)
                    : const Color(0xFFF1F5F9),
            width: isAccepted || isRejected ? 1.5 : 1.2,
          ),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    donation.imageUrl,
                    height: 84,
                    width: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 84,
                      width: 84,
                      color: const Color(0xFFE8F5E9),
                      child: const Icon(
                        Icons.fastfood_outlined,
                        size: 36,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          StatusPill(
                            status: donation.status.isNotEmpty
                                ? donation.status
                                : 'Pending',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${donation.quantity} servings • ${donation.category}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              donation.pickupAddress.isEmpty
                                  ? 'Hyderabad'
                                  : donation.pickupAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Posted: ${_formatDate(donation.createdAt)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (canDelete)
                  IconButton(
                    tooltip: isAdmin && !isOwner
                        ? 'Remove donation (Admin)'
                        : 'Delete donation',
                    icon: Icon(
                      Icons.delete_outline,
                      color: isAdmin && !isOwner
                          ? const Color(0xFFDC2626)
                          : Colors.red,
                    ),
                    onPressed: () => _deleteDonation(context),
                  ),
              ],
            ),

            // If Accepted or Rejected, show confirmation status banner
            if (isAccepted && donation.updatedBy.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      donation.hasWelfareChecklist
                          ? Icons.verified_rounded
                          : Icons.check_circle_rounded,
                      color: const Color(0xFF15803D),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        donation.hasWelfareChecklist
                            ? 'Accepted & Quality Verified by ${donation.updatedBy}'
                            : 'Accepted by ${donation.updatedBy}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                    if (donation.hasWelfareChecklist)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15803D),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Verified Fresh',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else if (isRejected && donation.updatedBy.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cancel_rounded,
                      color: Color(0xFFDC2626),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Declined by ${donation.updatedBy}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DonationSearchDelegate extends SearchDelegate {
  final DonationProvider provider;

  DonationSearchDelegate(this.provider);

  @override
  String get searchFieldLabel => 'Search donations';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      VoiceInputIconButton(
        tooltip: 'Search by voice',
        onResult: (value) {
          query = value;
          provider.updateSearchQuery(value);
        },
      ),
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          provider.updateSearchQuery('');
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    provider.updateSearchQuery(query);
    final results = provider.filteredDonations;

    return ListView.builder(
      itemCount: results.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final donation = results[index];
        return DonationCard(donation: donation);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    provider.updateSearchQuery(query);
    final suggestions = provider.filteredDonations;

    return ListView.builder(
      itemCount: suggestions.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final donation = suggestions[index];
        return ListTile(
          leading: const Icon(Icons.fastfood_outlined),
          title: Text(donation.foodName),
          subtitle: Text(
            '${donation.quantity} servings • ${donation.category} • ${donation.status}',
          ),
          onTap: () {
            close(context, null);
            Navigator.pushNamed(context, Routes.details, arguments: donation);
          },
        );
      },
    );
  }
}
