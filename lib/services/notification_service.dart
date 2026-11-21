import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/donation.dart';

/// Model representing an in-app notification.
class AppNotification {
  final String id;
  final String recipientId;
  final String recipientEmail;
  final String targetRole; // 'donor' or 'welfare'
  final String title;
  final String body;
  final String type; // 'donation_posted', 'donation_accepted', 'donation_rejected', 'new_donation', 'food_quality_verified'
  final String donationId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.recipientId,
    required this.recipientEmail,
    this.targetRole = 'donor',
    required this.title,
    required this.body,
    required this.type,
    this.donationId = '',
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime created = DateTime.now();
    final rawDate = data['createdAt'];
    if (rawDate is Timestamp) {
      created = rawDate.toDate();
    } else if (rawDate is String) {
      created = DateTime.tryParse(rawDate) ?? DateTime.now();
    }

    final rawType = data['type']?.toString() ?? 'general';
    final rawRecipientId = data['recipientId']?.toString() ?? '';
    final rawRecipientEmail = data['recipientEmail']?.toString() ?? '';

    // Automatically resolve role with backward compatibility
    String resolvedRole = data['targetRole']?.toString() ?? '';
    if (resolvedRole.isEmpty) {
      if (rawType == 'new_donation' ||
          rawRecipientId == 'all_welfare' ||
          rawRecipientEmail == 'all_welfare' ||
          rawRecipientId == 'welfare_centre') {
        resolvedRole = 'welfare';
      } else {
        resolvedRole = 'donor';
      }
    }

    return AppNotification(
      id: doc.id,
      recipientId: rawRecipientId,
      recipientEmail: rawRecipientEmail,
      targetRole: resolvedRole,
      title: data['title']?.toString() ?? 'Notification',
      body: data['body']?.toString() ?? '',
      type: rawType,
      donationId: data['donationId']?.toString() ?? '',
      isRead: data['isRead'] == true,
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'recipientEmail': recipientEmail,
      'targetRole': targetRole,
      'title': title,
      'body': body,
      'type': type,
      'donationId': donationId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Service handling in-app notifications and email triggers for donors and welfare centres.
class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Notify donor and welfare centres when a donation is created.
  static Future<void> notifyDonationCreated({
    required Donation donation,
    required String donorEmail,
  }) async {
    try {
      // 1. In-app Notification for the Donor
      if (donation.donorId.isNotEmpty || donorEmail.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'recipientId': donation.donorId,
          'recipientEmail': donorEmail,
          'targetRole': 'donor',
          'title': 'Donation Posted: ${donation.foodName}',
          'body':
              'Your donation of ${donation.quantity} servings of ${donation.foodName} has been submitted. Status: Pending. Welfare centres have been notified!',
          'type': 'donation_posted',
          'donationId': donation.id,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // 2. Email for the Donor (logged to Firestore `mail` collection)
      if (donorEmail.isNotEmpty) {
        await _queueEmail(
          to: donorEmail,
          subject: 'FoodLink: Donation Confirmed - ${donation.foodName}',
          text:
              'Hello ${donation.donorName},\n\nThank you for posting your food donation on FoodLink!\n\n'
              'Donation Summary:\n'
              '- Food: ${donation.foodName}\n'
              '- Category: ${donation.category}\n'
              '- Quantity: ${donation.quantity} servings\n'
              '- Pickup Address: ${donation.pickupAddress}\n'
              '- Contact: ${donation.contactNumber}\n'
              '- Status: Pending review by local welfare centres\n\n'
              'You can track this donation status (Pending, Accepted, or Rejected) anytime in your FoodLink Donation History.\n\n'
              'Best regards,\nFoodLink Team',
          html: '''
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e2e8f0; border-radius: 8px;">
              <h2 style="color: #0F5132; margin-top: 0;">FoodLink - Donation Confirmed</h2>
              <p>Hello <strong>${donation.donorName}</strong>,</p>
              <p>Thank you for contributing to reducing food waste and supporting local welfare organisations!</p>
              <div style="background-color: #F0FDF4; border-left: 4px solid #16A34A; padding: 12px 16px; margin: 16px 0;">
                <p style="margin: 4px 0;"><strong>Food:</strong> ${donation.foodName}</p>
                <p style="margin: 4px 0;"><strong>Servings:</strong> ${donation.quantity}</p>
                <p style="margin: 4px 0;"><strong>Category:</strong> ${donation.category}</p>
                <p style="margin: 4px 0;"><strong>Pickup Address:</strong> ${donation.pickupAddress}</p>
                <p style="margin: 4px 0;"><strong>Status:</strong> <span style="color: #D97706; font-weight: bold;">Pending Review</span></p>
              </div>
              <p>Welfare centres in your area have been notified. You can track whether this donation is Accepted or Rejected under <strong>Donation History</strong> in the FoodLink app.</p>
              <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;" />
              <p style="color: #64748B; font-size: 12px;">FoodLink App - Connecting Food Donors with Welfare Centres</p>
            </div>
          ''',
          donationId: donation.id,
        );
      }

      // 3. Find Welfare Centres to notify (all registered centres)
      final welfareEmails = <String>{};
      final welfareCentreIds = <String>[];

      try {
        final publicCentres =
            await _firestore.collection('public_welfare_centres').get();
        for (final doc in publicCentres.docs) {
          final email = doc.data()['email']?.toString();
          if (email != null && email.isNotEmpty && email.contains('@')) {
            welfareEmails.add(email);
          }
          welfareCentreIds.add(doc.id);
        }

        final registeredCentres =
            await _firestore.collection('welfare_centres').get();
        for (final doc in registeredCentres.docs) {
          final email = doc.data()['email']?.toString();
          if (email != null && email.isNotEmpty && email.contains('@')) {
            welfareEmails.add(email);
          }
          if (!welfareCentreIds.contains(doc.id)) {
            welfareCentreIds.add(doc.id);
          }
        }
      } catch (e) {
        debugPrint('Error gathering welfare centre emails: $e');
      }

      // 4. In-app Notification for Welfare Centres
      // Broadcast welfare notification
      await _firestore.collection('notifications').add({
        'recipientId': 'all_welfare',
        'recipientEmail': 'all_welfare',
        'targetRole': 'welfare',
        'title': 'New Food Donation Available!',
        'body':
            '${donation.foodName} (${donation.quantity} servings) posted by ${donation.donorName} at ${donation.pickupAddress}. Tap to review and accept.',
        'type': 'new_donation',
        'donationId': donation.id,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Also create targeted notifications for found centres
      for (final centreId in welfareCentreIds) {
        await _firestore.collection('notifications').add({
          'recipientId': centreId,
          'recipientEmail': 'welfare_centre',
          'targetRole': 'welfare',
          'title': 'New Donation: ${donation.foodName}',
          'body':
              '${donation.foodName} (${donation.quantity} servings) is available for pickup at ${donation.pickupAddress}.',
          'type': 'new_donation',
          'donationId': donation.id,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // 5. Emails for Welfare Centres
      for (final email in welfareEmails) {
        await _queueEmail(
          to: email,
          subject: 'FoodLink Alert: New Donation Available - ${donation.foodName}',
          text:
              'Dear Welfare Partner,\n\nA new food donation is available in your area!\n\n'
              '- Food: ${donation.foodName}\n'
              '- Quantity: ${donation.quantity} servings\n'
              '- Category: ${donation.category}\n'
              '- Donor Name: ${donation.donorName}\n'
              '- Donor Phone: (Shared upon accepting donation)\n'
              '- Pickup Address: ${donation.pickupAddress}\n\n'
              'Please open FoodLink and visit the Welfare Dashboard to Accept or Reject this donation request.\n\n'
              'Best regards,\nFoodLink Team',
          html: '''
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e2e8f0; border-radius: 8px;">
              <h2 style="color: #0F5132; margin-top: 0;">FoodLink - New Food Donation Alert</h2>
              <p>Dear Welfare Partner,</p>
              <p>A fresh food donation is ready for claiming:</p>
              <div style="background-color: #FEF3C7; border-left: 4px solid #D97706; padding: 12px 16px; margin: 16px 0;">
                <p style="margin: 4px 0;"><strong>Food:</strong> ${donation.foodName}</p>
                <p style="margin: 4px 0;"><strong>Quantity:</strong> ${donation.quantity} servings</p>
                <p style="margin: 4px 0;"><strong>Category:</strong> ${donation.category}</p>
                <p style="margin: 4px 0;"><strong>Donor:</strong> ${donation.donorName} <em>(Contact number shared upon accepting)</em></p>
                <p style="margin: 4px 0;"><strong>Pickup Address:</strong> ${donation.pickupAddress}</p>
              </div>
              <p>Please log in to the <strong>Welfare Dashboard</strong> on the FoodLink app to Accept or Reject this donation.</p>
              <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;" />
              <p style="color: #64748B; font-size: 12px;">FoodLink - Reducing food waste together</p>
            </div>
          ''',
          donationId: donation.id,
        );
      }
    } catch (e) {
      debugPrint('Error sending creation notifications/email: $e');
    }
  }

  /// Notify donor and welfare centre when a donation is accepted or rejected.
  static Future<void> notifyDonationStatusChanged({
    required Donation donation,
    required String newStatus,
    required String updatedBy,
    String? updatedByEmail,
  }) async {
    try {
      final isAccepted =
          newStatus.toLowerCase() == 'accepted' || newStatus.toLowerCase() == 'approved';
      final statusLabel = isAccepted ? 'Accepted' : 'Rejected';

      // 1. In-app Notification for Donor
      await _firestore.collection('notifications').add({
        'recipientId': donation.donorId,
        'recipientEmail': donation.donorEmail,
        'targetRole': 'donor',
        'title': isAccepted
            ? 'Donation Accepted! 🎉'
            : 'Donation Update: ${donation.foodName}',
        'body': isAccepted
            ? 'Great news! Your donation of ${donation.foodName} has been accepted by $updatedBy. Thank you for your support!'
            : 'Your donation of ${donation.foodName} was declined by $updatedBy.',
        'type': isAccepted ? 'donation_accepted' : 'donation_rejected',
        'donationId': donation.id,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Email for Donor
      if (donation.donorEmail.isNotEmpty) {
        await _queueEmail(
          to: donation.donorEmail,
          subject: 'FoodLink: Donation $statusLabel - ${donation.foodName}',
          text: isAccepted
              ? 'Hello ${donation.donorName},\n\nYour donation of "${donation.foodName}" has been ACCEPTED by $updatedBy!\n\n'
                  'They will contact you at ${donation.contactNumber} or arrive at ${donation.pickupAddress} for pickup.\n\n'
                  'Check your Donation History in the FoodLink app to see the updated status.\n\n'
                  'Thank you for making a difference!\nFoodLink Team'
              : 'Hello ${donation.donorName},\n\nYour donation of "${donation.foodName}" was DECLINED by $updatedBy.\n\n'
                  'You can view your donation history in the FoodLink app.\n\n'
                  'Best regards,\nFoodLink Team',
          html: isAccepted
              ? '''
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e2e8f0; border-radius: 8px;">
                  <h2 style="color: #15803D; margin-top: 0;">Donation Accepted! 🎉</h2>
                  <p>Hello <strong>${donation.donorName}</strong>,</p>
                  <p>Exciting news! Your donation of <strong>${donation.foodName}</strong> has been <strong>ACCEPTED</strong> by <strong>$updatedBy</strong>.</p>
                  <div style="background-color: #DCFCE7; border-left: 4px solid #16A34A; padding: 12px 16px; margin: 16px 0;">
                    <p style="margin: 4px 0;"><strong>Food:</strong> ${donation.foodName} (${donation.quantity} servings)</p>
                    <p style="margin: 4px 0;"><strong>Accepted by:</strong> $updatedBy</p>
                    <p style="margin: 4px 0;"><strong>Pickup Address:</strong> ${donation.pickupAddress}</p>
                    <p style="margin: 4px 0;"><strong>Status:</strong> <span style="color: #15803D; font-weight: bold;">Accepted</span></p>
                  </div>
                  <p>Your Donation History in the FoodLink app has been updated to reflect this status.</p>
                  <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;" />
                  <p style="color: #64748B; font-size: 12px;">FoodLink - Connecting Donors & Welfare Organisations</p>
                </div>
              '''
              : '''
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e2e8f0; border-radius: 8px;">
                  <h2 style="color: #DC2626; margin-top: 0;">Donation Update</h2>
                  <p>Hello <strong>${donation.donorName}</strong>,</p>
                  <p>Your donation of <strong>${donation.foodName}</strong> was declined by <strong>$updatedBy</strong>.</p>
                  <p>Your Donation History in the FoodLink app has been updated to <strong>Rejected</strong>.</p>
                  <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;" />
                  <p style="color: #64748B; font-size: 12px;">FoodLink - Connecting Donors & Welfare Organisations</p>
                </div>
              ''',
          donationId: donation.id,
        );
      }

      // 3. In-app Notification for Welfare Centre
      final centreEmail = updatedByEmail ?? 'welfare@foodlink.org';
      await _firestore.collection('notifications').add({
        'recipientId': 'welfare_centre',
        'recipientEmail': centreEmail,
        'targetRole': 'welfare',
        'title': 'Donation $statusLabel: ${donation.foodName}',
        'body': isAccepted
            ? 'You accepted ${donation.foodName} (${donation.quantity} servings) from ${donation.donorName}. Contact: ${donation.contactNumber}.'
            : 'You declined ${donation.foodName} from ${donation.donorName}.',
        'type': isAccepted ? 'donation_accepted' : 'donation_rejected',
        'donationId': donation.id,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Email confirmation to Welfare Centre
      await _queueEmail(
        to: centreEmail,
        subject: 'FoodLink: Donation $statusLabel Confirmation - ${donation.foodName}',
        text: isAccepted
            ? 'Hello $updatedBy,\n\nYou have ACCEPTED the donation of "${donation.foodName}" (${donation.quantity} servings).\n\n'
                'Donor Information for Pickup:\n'
                '- Donor: ${donation.donorName}\n'
                '- Phone: ${donation.contactNumber}\n'
                '- Pickup Address: ${donation.pickupAddress}\n\n'
                'Thank you for collecting this food!\nFoodLink Team'
            : 'Hello $updatedBy,\n\nYou have DECLINED the donation of "${donation.foodName}".\n\n'
                'Thank you,\nFoodLink Team',
        html: isAccepted
            ? '''
              <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e2e8f0; border-radius: 8px;">
                <h2 style="color: #0F5132; margin-top: 0;">Donation Accepted Confirmation</h2>
                <p>Hello <strong>$updatedBy</strong>,</p>
                <p>You have confirmed acceptance of the following donation:</p>
                <div style="background-color: #F0FDF4; border-left: 4px solid #16A34A; padding: 12px 16px; margin: 16px 0;">
                  <p style="margin: 4px 0;"><strong>Food:</strong> ${donation.foodName} (${donation.quantity} servings)</p>
                  <p style="margin: 4px 0;"><strong>Donor:</strong> ${donation.donorName}</p>
                  <p style="margin: 4px 0;"><strong>Contact:</strong> ${donation.contactNumber}</p>
                  <p style="margin: 4px 0;"><strong>Pickup Address:</strong> ${donation.pickupAddress}</p>
                </div>
                <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;" />
                <p style="color: #64748B; font-size: 12px;">FoodLink Welfare Dashboard</p>
              </div>
            '''
            : '''
              <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e2e8f0; border-radius: 8px;">
                <h2 style="color: #DC2626; margin-top: 0;">Donation Declined Confirmation</h2>
                <p>Hello <strong>$updatedBy</strong>,</p>
                <p>You declined the donation for <strong>${donation.foodName}</strong>.</p>
                <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;" />
                <p style="color: #64748B; font-size: 12px;">FoodLink Welfare Dashboard</p>
              </div>
            ''',
        donationId: donation.id,
      );
    } catch (e) {
      debugPrint('Error sending status change notification/email: $e');
    }
  }

  /// Notify donor and welfare centre when a welfare centre completes the quality checklist.
  static Future<void> notifyFoodQualityVerified({
    required Donation donation,
    required String verifiedBy,
    required bool isFresh,
    required bool isGoodQuality,
    required bool isPackagingIntact,
    String? feedbackNotes,
  }) async {
    try {
      // 1. In-app Notification for Donor
      await _firestore.collection('notifications').add({
        'recipientId': donation.donorId,
        'recipientEmail': donation.donorEmail,
        'targetRole': 'donor',
        'title': 'Food Quality Verified! 🌟',
        'body':
            '$verifiedBy inspected your donation of "${donation.foodName}": Confirmed ${isFresh ? 'Fresh' : 'Inspected'} & ${isGoodQuality ? 'Good Quality' : 'Reviewed'}${feedbackNotes != null && feedbackNotes.isNotEmpty ? ' ("$feedbackNotes")' : ''}. Thank you for maintaining food safety standards!',
        'type': 'food_quality_verified',
        'donationId': donation.id,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Email for Donor
      if (donation.donorEmail.isNotEmpty) {
        await _queueEmail(
          to: donation.donorEmail,
          subject: 'FoodLink: Food Freshness & Quality Verified - ${donation.foodName}',
          text:
              'Hello ${donation.donorName},\n\nGreat news! $verifiedBy has completed the quality inspection for your donation of "${donation.foodName}".\n\n'
              'Inspection Checklist Summary:\n'
              '- Food Freshness: ${isFresh ? 'Confirmed Fresh' : 'Checked'}\n'
              '- Hygiene & Quality: ${isGoodQuality ? 'Confirmed Good Quality' : 'Checked'}\n'
              '- Packaging Condition: ${isPackagingIntact ? 'Secure & Intact' : 'Checked'}\n'
              '${feedbackNotes != null && feedbackNotes.isNotEmpty ? '- Welfare Centre Feedback: "$feedbackNotes"\n' : ''}\n'
              'Thank you for donating safe, healthy food to our community!\n\nBest regards,\nFoodLink Team',
          html: '''
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e2e8f0; border-radius: 8px;">
              <h2 style="color: #15803D; margin-top: 0;">Food Quality Verified! 🌟</h2>
              <p>Hello <strong>${donation.donorName}</strong>,</p>
              <p><strong>$verifiedBy</strong> has inspected your donation of <strong>${donation.foodName}</strong> and confirmed its quality:</p>
              <div style="background-color: #DCFCE7; border-left: 4px solid #16A34A; padding: 12px 16px; margin: 16px 0;">
                <p style="margin: 4px 0;"><strong>✓ Food Freshness:</strong> ${isFresh ? 'Confirmed Fresh' : 'Reviewed'}</p>
                <p style="margin: 4px 0;"><strong>✓ Quality & Hygiene:</strong> ${isGoodQuality ? 'Good Quality' : 'Reviewed'}</p>
                <p style="margin: 4px 0;"><strong>✓ Packaging:</strong> ${isPackagingIntact ? 'Secure & Intact' : 'Reviewed'}</p>
                ${feedbackNotes != null && feedbackNotes.isNotEmpty ? '<p style="margin: 4px 0;"><strong>Notes:</strong> "$feedbackNotes"</p>' : ''}
              </div>
              <p>Your contribution directly fed individuals in need with fresh, high-standard food. Thank you!</p>
              <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;" />
              <p style="color: #64748B; font-size: 12px;">FoodLink Quality Assurance</p>
            </div>
          ''',
          donationId: donation.id,
        );
      }

      // 3. In-app Notification for Welfare Centre
      await _firestore.collection('notifications').add({
        'recipientId': 'welfare_centre',
        'recipientEmail': 'welfare_centre',
        'targetRole': 'welfare',
        'title': 'Inspection Recorded: ${donation.foodName}',
        'body':
            'You completed the quality checklist for "${donation.foodName}". Freshness & hygiene confirmed.',
        'type': 'inspection_completed',
        'donationId': donation.id,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending quality verification notification: $e');
    }
  }

  /// Queues an email document into the Firestore `mail` collection (standard Firebase Trigger Email format).
  static Future<void> _queueEmail({
    required String to,
    required String subject,
    required String text,
    required String html,
    String? donationId,
  }) async {
    try {
      await _firestore.collection('mail').add({
        'to': [to],
        'message': {
          'subject': subject,
          'text': text,
          'html': html,
        },
        'donationId': donationId ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'sent',
      });
      debugPrint('Email queued to $to: $subject');
    } catch (e) {
      debugPrint('Error writing to mail collection: $e');
    }
  }

  /// Stream notifications for a specific user or welfare centre with strict role separation.
  static Stream<List<AppNotification>> streamNotifications({
    String? userId,
    String? userEmail,
    String? role, // 'donor' or 'welfare'
    bool isWelfare = false,
  }) {
    final effectiveRole = role ?? (isWelfare ? 'welfare' : 'donor');

    return _firestore
        .collection('notifications')
        .snapshots()
        .map((snapshot) {
          final list = <AppNotification>[];
          final cleanEmail = userEmail?.trim().toLowerCase() ?? '';
          final cleanUid = userId?.trim() ?? '';

          for (final doc in snapshot.docs) {
            try {
              final notif = AppNotification.fromDoc(doc);
              final notifUid = notif.recipientId.trim();
              final notifEmail = notif.recipientEmail.trim().toLowerCase();

              // Strictly separate donor notifications from welfare notifications
              if (notif.targetRole != effectiveRole) {
                continue;
              }

              bool isMatch = false;
              if (effectiveRole == 'welfare') {
                if (notifUid == 'all_welfare' ||
                    notifEmail == 'all_welfare' ||
                    notifUid == 'welfare_centre' ||
                    notifUid == cleanUid ||
                    (cleanEmail.isNotEmpty && notifEmail == cleanEmail)) {
                  isMatch = true;
                }
              } else {
                if (cleanUid.isNotEmpty && notifUid == cleanUid) {
                  isMatch = true;
                } else if (cleanEmail.isNotEmpty && notifEmail == cleanEmail) {
                  isMatch = true;
                }
              }

              if (isMatch) {
                list.add(notif);
              }
            } catch (e) {
              debugPrint('Error parsing notification ${doc.id}: $e');
            }
          }

          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Stream unread notifications count for a specific role ('donor' or 'welfare').
  static Stream<int> streamUnreadCount({
    String? userId,
    String? userEmail,
    String? role,
    bool isWelfare = false,
  }) {
    return streamNotifications(
      userId: userId,
      userEmail: userEmail,
      role: role,
      isWelfare: isWelfare,
    ).map((list) => list.where((n) => !n.isRead).length);
  }

  /// Mark a notification as read.
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for current user/centre role.
  static Future<void> markAllAsRead({
    String? userId,
    String? userEmail,
    String? role,
    bool isWelfare = false,
  }) async {
    try {
      final effectiveRole = role ?? (isWelfare ? 'welfare' : 'donor');
      final snapshot = await _firestore.collection('notifications').get();
      final batch = _firestore.batch();
      final cleanEmail = userEmail?.trim().toLowerCase() ?? '';
      final cleanUid = userId?.trim() ?? '';

      for (final doc in snapshot.docs) {
        final notif = AppNotification.fromDoc(doc);
        if (notif.isRead || notif.targetRole != effectiveRole) continue;

        bool isMatch = false;
        if (effectiveRole == 'welfare') {
          if (notif.recipientId == 'all_welfare' ||
              notif.recipientEmail == 'all_welfare' ||
              notif.recipientId == 'welfare_centre' ||
              notif.recipientId == cleanUid ||
              (cleanEmail.isNotEmpty && notif.recipientEmail == cleanEmail)) {
            isMatch = true;
          }
        } else {
          if (cleanUid.isNotEmpty && notif.recipientId == cleanUid) {
            isMatch = true;
          } else if (cleanEmail.isNotEmpty &&
              notif.recipientEmail == cleanEmail) {
            isMatch = true;
          }
        }

        if (isMatch) {
          batch.update(doc.reference, {'isRead': true});
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  /// Open external email client if user desires direct interaction.
  static Future<void> launchMailClient({
    required String to,
    required String subject,
    required String body,
  }) async {
    final uri = Uri.parse(
      'mailto:$to?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching mail app: $e');
    }
  }
}
