import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/donation.dart';
import '../services/notification_service.dart';
import '../utils/admin_config.dart';
import '../utils/app_theme.dart';
import '../widgets/foodlink_ui_components.dart';
import '../widgets/welfare_quality_checklist_dialog.dart';

class DonationDetailsScreen extends StatefulWidget {
  final Donation? donation;

  const DonationDetailsScreen({super.key, required this.donation});

  @override
  State<DonationDetailsScreen> createState() => _DonationDetailsScreenState();
}

class _DonationDetailsScreenState extends State<DonationDetailsScreen> {
  int _currentImageIndex = 0;
  String? _statusOverride;
  Map<String, dynamic>? _localWelfareChecklist;

  @override
  void initState() {
    super.initState();
    _localWelfareChecklist = widget.donation?.welfareChecklist;
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

  String _formatDateTime(DateTime dt) {
    final date = _formatDate(dt);
    final hour = dt.hour == 0
        ? 12
        : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$date, $hour:$minute $period';
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _statusOverride = newStatus;
    });

    final donationId = widget.donation?.id;
    final user = FirebaseAuth.instance.currentUser;
    final updatedBy = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : (user?.email?.isNotEmpty == true ? user!.email! : 'Welfare Centre');

    if (donationId != null && !donationId.startsWith('mock_')) {
      try {
        await FirebaseFirestore.instance
            .collection('donations')
            .doc(donationId)
            .update({
          'status': newStatus,
          'updatedBy': updatedBy,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (widget.donation != null) {
          await NotificationService.notifyDonationStatusChanged(
            donation: widget.donation!,
            newStatus: newStatus,
            updatedBy: updatedBy,
            updatedByEmail: user?.email,
          );
        }
      } catch (e) {
        debugPrint('Error updating donation status: $e');
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus == 'accepted'
              ? 'Donation accepted! Please complete the food freshness & quality checklist.'
              : 'Donation rejected. Notification and email sent to donor.',
        ),
        backgroundColor:
            newStatus == 'accepted' ? AppTheme.primaryGreen : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );

    // Prompt the food quality & freshness checklist immediately after accepting!
    if (newStatus == 'accepted' && widget.donation != null) {
      final currentDonation = widget.donation!.copyWith(
        status: newStatus,
        updatedBy: updatedBy,
      );
      WelfareQualityChecklistSheet.show(
        context,
        donation: currentDonation,
        onCompleted: (checklist) {
          setState(() {
            _localWelfareChecklist = checklist;
          });
        },
      );
    }
  }

  Future<void> _callDonor(String contactNumber) async {
    final cleaned = contactNumber.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contact number available.')),
      );
      return;
    }

    try {
      final uri = Uri(scheme: 'tel', path: cleaned);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open phone dialer.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error dialing donor: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteDonation(
      BuildContext context, Donation donation) async {
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
              ? 'As an administrator, are you sure you want to remove "${donation.foodName}" from the list?'
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
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    // Fallback donation if none passed
    final donation = widget.donation ??
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
        );

    final status = _statusOverride ??
        (donation.status.isNotEmpty ? donation.status : 'Pending');
    final effectiveStatus = status.toLowerCase();
    final isAccepted =
        effectiveStatus == 'accepted' || effectiveStatus == 'approved';
    final isRejected = effectiveStatus == 'rejected';
    final currentDonation = donation.copyWith(
      status: effectiveStatus,
      welfareChecklist: _localWelfareChecklist,
    );

    // 3 Images matching the "1/3" carousel and "Additional Images" gallery
    final List<String> galleryImages = [
      donation.imageUrl.isNotEmpty
          ? donation.imageUrl
          : 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=600',
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600',
      'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=600',
    ];

    final user = FirebaseAuth.instance.currentUser;
    final isOwner = donation.donorId == user?.uid ||
        (user?.email != null && donation.donorEmail == user!.email);
    final isAdmin = isWelfareAdmin(user);
    final canDelete = isOwner || isAdmin;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1E293B),
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Donation Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: [
          if (canDelete)
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFDC2626),
                size: 22,
              ),
              tooltip: isAdmin && !isOwner
                  ? 'Remove donation (Admin)'
                  : 'Delete donation',
              onPressed: () => _confirmDeleteDonation(context, donation),
            ),
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: Color(0xFF1E293B),
              size: 22,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.phone_outlined,
                            color: Color(0xFF15803D),
                          ),
                          title: const Text('Call Donor'),
                          onTap: () {
                            Navigator.pop(context);
                            _callDonor(donation.contactNumber);
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.share_outlined,
                            color: Color(0xFF64748B),
                          ),
                          title: const Text('Share Donation'),
                          onTap: () => Navigator.pop(context),
                        ),
                        if (canDelete) ...[
                          const Divider(),
                          ListTile(
                            leading: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFDC2626),
                            ),
                            title: Text(
                              isAdmin && !isOwner
                                  ? 'Remove Donation (Admin)'
                                  : 'Delete Donation',
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _confirmDeleteDonation(context, donation);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image Carousel with "1/3" Indicator Chip
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: Image.network(
                      galleryImages[_currentImageIndex],
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 220,
                        color: const Color(0xFFE8F5E9),
                        child: const Icon(
                          Icons.restaurant,
                          color: Color(0xFF15803D),
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                ),
                // "1/3" page indicator chip
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1}/${galleryImages.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Food Name & Status Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    donation.foodName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                StatusPill(status: status),
              ],
            ),
            const SizedBox(height: 16),

            // Metadata Info Rows
            _buildInfoRow(
              icon: Icons.category_outlined,
              label: 'Category',
              value: donation.category,
            ),
            _buildInfoRow(
              icon: Icons.layers_outlined,
              label: 'Quantity',
              value:
                  '${donation.quantity} ${donation.category == 'Meals' ? 'plates' : (donation.category == 'Fruits' ? 'kg' : (donation.category == 'Beverages' ? 'cups' : 'servings'))}',
            ),
            _buildInfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Expiry date',
              value: _formatDate(donation.expiryDate),
            ),
            _buildInfoRow(
              icon: Icons.phone_outlined,
              label: 'Contact number',
              value: donation.contactNumber,
              isPhone: true,
              onTap: () => _callDonor(donation.contactNumber),
            ),
            _buildInfoRow(
              icon: Icons.badge_outlined,
              label: 'Donor ID',
              value: donation.donorId.isNotEmpty
                  ? donation.donorId
                  : 'JLF2gw2ZbaA6qH3derzVHEE1tr2',
            ),
            _buildInfoRow(
              icon: Icons.calendar_month_outlined,
              label: 'Posted on',
              value: _formatDateTime(donation.createdAt),
            ),
            const SizedBox(height: 20),

            // Food Safety Checklist Card
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4), // Mint background
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFDCFCE7),
                  width: 1.2,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF15803D),
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Food safety checklist',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF14532D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSafetyItem('The food is fresh and safe to consume.'),
                  _buildSafetyItem('Stored at a proper temperature.'),
                  _buildSafetyItem('Properly packed and sealed.'),
                  _buildSafetyItem('It is within the expiry date.'),
                ],
              ),
            ),

            // Welfare Centre Quality Inspection Checklist (Was food fresh & good?)
            if (isAccepted) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _localWelfareChecklist != null
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _localWelfareChecklist != null
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFFDE68A),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _localWelfareChecklist != null
                                  ? Icons.verified_rounded
                                  : Icons.fact_check_outlined,
                              color: _localWelfareChecklist != null
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFD97706),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Welfare Quality Inspection',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _localWelfareChecklist != null
                                    ? const Color(0xFF14532D)
                                    : const Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                        if (_localWelfareChecklist != null)
                          TextButton(
                            onPressed: () {
                              WelfareQualityChecklistSheet.show(
                                context,
                                donation: currentDonation,
                                onCompleted: (checklist) {
                                  setState(
                                    () => _localWelfareChecklist = checklist,
                                  );
                                },
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
                                color: Color(0xFF15803D),
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_localWelfareChecklist != null) ...[
                      Text(
                        'Verified by ${_localWelfareChecklist!['verifiedBy'] ?? (donation.updatedBy.isNotEmpty ? donation.updatedBy : 'Welfare Centre')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSafetyItem(
                        _localWelfareChecklist!['isFresh'] == true
                            ? 'Food freshness confirmed (fresh & safe).'
                            : 'Food freshness checked by centre.',
                      ),
                      _buildSafetyItem(
                        _localWelfareChecklist!['isGoodQuality'] == true
                            ? 'Food quality & hygiene confirmed (good condition).'
                            : 'Food quality reviewed.',
                      ),
                      _buildSafetyItem(
                        _localWelfareChecklist!['isPackagingIntact'] == true
                            ? 'Packaging secure and intact with no leaks.'
                            : 'Packaging inspected.',
                      ),
                      _buildSafetyItem(
                        _localWelfareChecklist!['isSafeForDistribution'] ==
                                true
                            ? 'Approved and safe for direct distribution.'
                            : 'Distribution condition checked.',
                      ),
                      if (_localWelfareChecklist!['feedbackNotes'] != null &&
                          _localWelfareChecklist!['feedbackNotes']
                              .toString()
                              .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFDCFCE7),
                            ),
                          ),
                          child: Text(
                            'Donor Feedback: "${_localWelfareChecklist!['feedbackNotes']}"',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ] else ...[
                      const Text(
                        'Donation accepted! Please complete the food freshness and hygiene checklist upon receiving the food.',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF78350F)),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          WelfareQualityChecklistSheet.show(
                            context,
                            donation: currentDonation,
                            onCompleted: (checklist) {
                              setState(
                                () => _localWelfareChecklist = checklist,
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.fact_check, size: 16),
                        label: const Text('Complete Quality Checklist'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),

            // Additional Images Section
            Row(
              children: const [
                Icon(
                  Icons.photo_library_outlined,
                  size: 20,
                  color: Color(0xFF1E293B),
                ),
                SizedBox(width: 8),
                Text(
                  'Additional Images',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row of 3 Thumbnails
            Row(
              children: List.generate(galleryImages.length, (idx) {
                final isSelected = _currentImageIndex == idx;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentImageIndex = idx;
                      });
                    },
                    child: Container(
                      height: 80,
                      margin: EdgeInsets.only(
                        left: idx == 0 ? 0 : 6,
                        right: idx == galleryImages.length - 1 ? 0 : 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF15803D)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          galleryImages[idx],
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: const Color(0xFFE8F5E9),
                            child: const Icon(
                              Icons.restaurant,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 100), // Spacing for bottom action bar
          ],
        ),
      ),

      // Sticky Bottom Action Bar with Accept & Reject Buttons
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: isAccepted
              ? Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            WelfareQualityChecklistSheet.show(
                              context,
                              donation: currentDonation,
                              onCompleted: (checklist) {
                                setState(
                                  () => _localWelfareChecklist = checklist,
                                );
                              },
                            );
                          },
                          icon: Icon(
                            _localWelfareChecklist != null
                                ? Icons.verified_rounded
                                : Icons.fact_check_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                          label: Text(
                            _localWelfareChecklist != null
                                ? 'Update Quality Checklist'
                                : 'Verify Food Freshness',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _localWelfareChecklist != null
                                ? const Color(0xFF15803D)
                                : const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      onPressed: () => _callDonor(donation.contactNumber),
                      icon: const Icon(Icons.phone, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF0F5132),
                        padding: const EdgeInsets.all(13),
                      ),
                      tooltip: 'Call Donor',
                    ),
                  ],
                )
              : isRejected
                  ? Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cancel_rounded,
                            color: Color(0xFFDC2626),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Donation Declined',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        // Accept Button
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => _updateStatus('accepted'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF0F5132), // Deep green
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.check,
                                      size: 20, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'Accept',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Reject Button
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => _updateStatus('rejected'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFFDC2626), // Solid red
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.close,
                                      size: 20, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'Reject',
                                    style: TextStyle(
                                      fontSize: 16,
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
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isPhone = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Icon(icon, size: 19, color: const Color(0xFF64748B)),
            const SizedBox(width: 10),
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isPhone
                      ? const Color(0xFF15803D)
                      : const Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A34A),
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
