import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_donation_app/models/donation.dart';
import 'package:food_donation_app/main.dart';
import 'package:food_donation_app/screens/nearest_welfare_centers_screen.dart';
import 'package:food_donation_app/screens/support_chat_screen.dart';
import 'package:food_donation_app/utils/voice_input.dart';

void main() {
  testWidgets('Firebase startup errors are shown instead of a blank screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const FirebaseInitializationErrorScreen(
        error: 'Missing Firebase web configuration',
      ),
    );

    expect(
      find.text('FoodLink could not connect to Firebase.'),
      findsOneWidget,
    );
    expect(find.text('Missing Firebase web configuration'), findsOneWidget);
  });

  test('donation data keeps ownership and food-safety confirmations', () {
    final donation = Donation.fromMap({
      'userId': 'donor-123',
      'foodName': 'Fresh apples',
      'category': 'Fruits',
      'quantity': 5,
      'expiryDate': Timestamp.fromDate(DateTime(2026, 10, 20)),
      'createdAt': Timestamp.fromDate(DateTime(2026, 10, 13)),
      'foodSafetyChecklist': {
        'fresh': true,
        'properlyStored': true,
        'expiryDateConfirmed': true,
      },
    }, 'donation-123');

    expect(donation.donorId, 'donor-123');
    expect(donation.foodSafetyChecklist['fresh'], isTrue);
    expect(donation.foodSafetyChecklist['properlyStored'], isTrue);
    expect(donation.foodSafetyChecklist['expiryDateConfirmed'], isTrue);
  });

  testWidgets('nearest welfare centers screen omits hard-coded centers', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NearestWelfareCentersScreen(
          centersStream: Stream.value(const []),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Nearest Welfare Centers'), findsWidgets);
    expect(find.text('Hope Shelter'), findsNothing);
    expect(find.text('Your nearby location'), findsNothing);
  });

  testWidgets('voice input button renders without emitting a result', (
    WidgetTester tester,
  ) async {
    String? recognizedText;
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VoiceInputButton(
            label: 'Use voice',
            controller: controller,
            onResult: (value) => recognizedText = value,
          ),
        ),
      ),
    );

    expect(find.text('Use voice'), findsOneWidget);
    expect(find.byType(VoiceInputButton), findsOneWidget);
    expect(controller.text, isEmpty);
    expect(recognizedText, isNull);
  });

  testWidgets('support chat answers food-safety questions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SupportChatScreen()));

    await tester.enterText(find.byType(TextField), 'How do I donate food?');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();

    expect(find.textContaining('Open Donate'), findsOneWidget);
    expect(find.byTooltip('Speak your question'), findsOneWidget);
  });

  testWidgets('support chat answers common wording for food-safety questions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SupportChatScreen()));

    await tester.enterText(
      find.byType(TextField),
      'How do I keep donated food fresh?',
    );
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();

    expect(find.textContaining('Only donate fresh food'), findsOneWidget);
  });

  testWidgets('support chat explains certificate permission errors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SupportChatScreen()));

    await tester.enterText(
      find.byType(TextField),
      'Account created but certificate upload failed: permission-denied',
    );
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();

    expect(
      find.textContaining('Do not create another account'),
      findsOneWidget,
    );
    expect(find.textContaining('Firebase Storage rules'), findsOneWidget);
  });

  testWidgets('support chat explains nearby-centre permission errors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SupportChatScreen()));

    await tester.enterText(
      find.byType(TextField),
      'Unable to load welfare centres: cloud_firestore permission-denied',
    );
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();

    expect(find.textContaining('approved centres only'), findsOneWidget);
    expect(find.textContaining('Firestore rules'), findsOneWidget);
  });

  testWidgets('support chat quick actions give matching help', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SupportChatScreen()));

    await tester.tap(find.text('Find a centre'));
    await tester.pump();

    expect(find.textContaining('Open Nearest Welfare Centers'), findsOneWidget);
  });

  test('donation tracks status (pending, accepted, rejected), donor email and updater', () {
    final pendingDonation = Donation.fromMap({
      'userId': 'donor-001',
      'donorEmail': 'donor@example.com',
      'foodName': 'Vegetable Biryani',
      'category': 'Meals',
      'quantity': 10,
      'status': 'pending',
    }, 'd-1');
    expect(pendingDonation.status, 'pending');
    expect(pendingDonation.donorEmail, 'donor@example.com');

    final acceptedDonation = Donation.fromMap({
      'userId': 'donor-001',
      'donorEmail': 'donor@example.com',
      'foodName': 'Vegetable Biryani',
      'status': 'accepted',
      'updatedBy': 'Hope Welfare Centre',
    }, 'd-2');
    expect(acceptedDonation.status, 'accepted');
    expect(acceptedDonation.updatedBy, 'Hope Welfare Centre');

    final rejectedDonation = Donation.fromMap({
      'userId': 'donor-001',
      'donorEmail': 'donor@example.com',
      'foodName': 'Vegetable Biryani',
      'status': 'rejected',
      'updatedBy': 'Hope Welfare Centre',
    }, 'd-3');
    expect(rejectedDonation.status, 'rejected');
    expect(rejectedDonation.updatedBy, 'Hope Welfare Centre');

    final map = acceptedDonation.toMap();
    expect(map['status'], 'accepted');
    expect(map['updatedBy'], 'Hope Welfare Centre');
    expect(map['donorEmail'], 'donor@example.com');
  });

  test('donation supports welfare freshness & quality inspection checklist', () {
    final inspectedDonation = Donation.fromMap({
      'userId': 'donor-001',
      'donorEmail': 'donor@example.com',
      'foodName': 'Rice & Dal',
      'status': 'accepted',
      'updatedBy': 'Ananda Orphanage',
      'welfareChecklist': {
        'isFresh': true,
        'isGoodQuality': true,
        'isPackagingIntact': true,
        'isSafeForDistribution': true,
        'feedbackNotes': 'Food was hot and very fresh!',
        'verifiedBy': 'Ananda Orphanage',
      },
    }, 'd-inspect');

    expect(inspectedDonation.hasWelfareChecklist, isTrue);
    expect(inspectedDonation.isFoodFreshConfirmed, isTrue);
    expect(inspectedDonation.isFoodGoodQualityConfirmed, isTrue);
    expect(inspectedDonation.welfareChecklist!['feedbackNotes'], 'Food was hot and very fresh!');

    final map = inspectedDonation.toMap();
    expect(map['welfareChecklist'], isNotNull);
    expect((map['welfareChecklist'] as Map)['isFresh'], isTrue);
  });
}
