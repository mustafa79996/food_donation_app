import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/donation.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';

/// Modal bottom sheet allowing a Welfare Centre to verify the freshness,
/// quality, and packaging of an accepted food donation.
class WelfareQualityChecklistSheet extends StatefulWidget {
  final Donation donation;
  final ValueChanged<Map<String, dynamic>>? onCompleted;

  const WelfareQualityChecklistSheet({
    super.key,
    required this.donation,
    this.onCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required Donation donation,
    ValueChanged<Map<String, dynamic>>? onCompleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WelfareQualityChecklistSheet(
        donation: donation,
        onCompleted: onCompleted,
      ),
    );
  }

  @override
  State<WelfareQualityChecklistSheet> createState() =>
      _WelfareQualityChecklistSheetState();
}

class _WelfareQualityChecklistSheetState
    extends State<WelfareQualityChecklistSheet> {
  bool _isFresh = true;
  bool _isGoodQuality = true;
  bool _isPackagingIntact = true;
  bool _isSafeForDistribution = true;
  final TextEditingController _notesController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.donation.welfareChecklist;
    if (existing != null) {
      _isFresh = existing['isFresh'] != false;
      _isGoodQuality = existing['isGoodQuality'] != false;
      _isPackagingIntact = existing['isPackagingIntact'] != false;
      _isSafeForDistribution = existing['isSafeForDistribution'] != false;
      _notesController.text = existing['feedbackNotes']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitChecklist() async {
    setState(() => _submitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final verifiedBy = user?.displayName?.isNotEmpty == true
          ? user!.displayName!
          : (user?.email?.isNotEmpty == true
              ? user!.email!
              : (widget.donation.updatedBy.isNotEmpty
                  ? widget.donation.updatedBy
                  : 'Welfare Centre'));

      final checklistData = {
        'isFresh': _isFresh,
        'isGoodQuality': _isGoodQuality,
        'isPackagingIntact': _isPackagingIntact,
        'isSafeForDistribution': _isSafeForDistribution,
        'feedbackNotes': _notesController.text.trim(),
        'verifiedBy': verifiedBy,
        'verifiedAt': FieldValue.serverTimestamp(),
      };

      // 1. Update donation document in Firestore
      if (!widget.donation.id.startsWith('mock_')) {
        await FirebaseFirestore.instance
            .collection('donations')
            .doc(widget.donation.id)
            .update({
          'welfareChecklist': checklistData,
          'qualityStatus':
              _isFresh && _isGoodQuality ? 'verified_good' : 'reviewed',
        });
      }

      // 2. Notify donor with in-app notification & confirmation email
      await NotificationService.notifyFoodQualityVerified(
        donation: widget.donation,
        verifiedBy: verifiedBy,
        isFresh: _isFresh,
        isGoodQuality: _isGoodQuality,
        isPackagingIntact: _isPackagingIntact,
        feedbackNotes: _notesController.text.trim(),
      );

      widget.onCompleted?.call(checklistData);

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Quality checklist submitted! Donor has been notified.',
          ),
          backgroundColor: AppTheme.primaryGreen,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save inspection checklist: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.fact_check_rounded,
                      color: Color(0xFF15803D),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Food Quality & Freshness',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Checklist for ${widget.donation.foodName} (${widget.donation.quantity} servings)',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 14),

              const Text(
                'Welfare Centre Inspection Checklist',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Please verify the condition of the accepted food upon receipt:',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),

              // Item 1: Was food fresh?
              _buildCheckTile(
                title: 'Was the food fresh?',
                subtitle:
                    'Freshly prepared or properly preserved, within safe consumption time.',
                value: _isFresh,
                onChanged: (val) => setState(() => _isFresh = val ?? false),
                icon: Icons.eco_rounded,
              ),

              // Item 2: Was food good quality?
              _buildCheckTile(
                title: 'Was the food good quality & hygienic?',
                subtitle:
                    'Clean appearance, pleasant aroma, with no signs of spoilage or discoloration.',
                value: _isGoodQuality,
                onChanged: (val) =>
                    setState(() => _isGoodQuality = val ?? false),
                icon: Icons.thumb_up_alt_rounded,
              ),

              // Item 3: Was packaging intact?
              _buildCheckTile(
                title: 'Was packaging secure & intact?',
                subtitle:
                    'Properly covered, sealed containers with no leaks or tampering.',
                value: _isPackagingIntact,
                onChanged: (val) =>
                    setState(() => _isPackagingIntact = val ?? false),
                icon: Icons.inventory_2_rounded,
              ),

              // Item 4: Safe for distribution?
              _buildCheckTile(
                title: 'Approved & safe for distribution?',
                subtitle:
                    'Ready to be served or distributed directly to beneficiaries.',
                value: _isSafeForDistribution,
                onChanged: (val) =>
                    setState(() => _isSafeForDistribution = val ?? false),
                icon: Icons.check_circle_rounded,
              ),

              const SizedBox(height: 12),

              // Feedback / Remarks TextField
              const Text(
                'Remarks / Feedback for Donor (Optional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g., Food arrived fresh, packaged well, and warm!',
                  hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryGreen),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit & Cancel Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text(
                        'Later',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _submitChecklist,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.verified_rounded, size: 18),
                      label: Text(
                        _submitting ? 'Saving...' : 'Confirm Quality',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: value ? const Color(0xFF15803D) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: value
                        ? const Color(0xFF15803D)
                        : const Color(0xFF334155),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
