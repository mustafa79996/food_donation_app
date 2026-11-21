import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_donation_app/screens/support_chat_screen.dart';
import 'package:food_donation_app/utils/support_chat_responder.dart';

void main() {
  group('SupportChatResponder (Mia Live Agent) Tests', () {
    test('agent identity answers with Mia as live support agent', () {
      final nameReply = SupportChatResponder.replyTo('What is your name?');
      expect(nameReply, contains("I'm Mia"));
      expect(nameReply, contains('live support agent'));

      final whoReply = SupportChatResponder.replyTo('Who are you?');
      expect(whoReply, contains("I'm Mia"));

      final isMiaReply = SupportChatResponder.replyTo('Are you Mia?');
      expect(isMiaReply, contains("I'm Mia"));
    });

    test('greetings and polite conversational pleasantries', () {
      final greeting = SupportChatResponder.replyTo('Hello');
      expect(greeting, contains('Mia'));
      expect(greeting, contains('live support agent'));

      final howAreYou = SupportChatResponder.replyTo('How are you doing?');
      expect(howAreYou, contains('doing great'));

      final thanks = SupportChatResponder.replyTo('Thank you so much!');
      expect(thanks, contains("You're very welcome"));

      final bye = SupportChatResponder.replyTo('Goodbye');
      expect(bye, contains('Goodbye'));
    });

    test('answers food donation inquiries including cooked food and pickup', () {
      final generalDonate = SupportChatResponder.replyTo('How do I donate food?');
      expect(generalDonate, contains('Open Donate'));

      final cookedDonate = SupportChatResponder.replyTo('Can I donate cooked food?');
      expect(cookedDonate, contains('cooked food can be donated'));
      expect(cookedDonate, contains('Open Donate'));

      final pickup = SupportChatResponder.replyTo('Who will pickup the donation?');
      expect(pickup, contains('coordinate pickup'));

      final cancel = SupportChatResponder.replyTo('How to cancel my donation?');
      expect(cancel, contains('My Donations'));

      final free = SupportChatResponder.replyTo('Is there any fee or is it free?');
      expect(free, contains('100% free'));
    });

    test('answers welfare centre registration and verification status', () {
      final register = SupportChatResponder.replyTo('How to register a welfare centre?');
      expect(register, contains('register a welfare centre'));

      final pending = SupportChatResponder.replyTo('Why is my centre status pending?');
      expect(pending, contains('Centre applications stay pending'));

      final claim = SupportChatResponder.replyTo('How can welfare centres accept food?');
      expect(claim, contains('Accept Donation'));
    });

    test('answers food safety and packaging questions', () {
      final safety = SupportChatResponder.replyTo('What are the food safety guidelines?');
      expect(safety, contains('Only donate fresh food'));

      final packaging = SupportChatResponder.replyTo('What packaging container should I use?');
      expect(packaging, contains('food-grade'));
    });

    test('answers location and nearest welfare centres questions', () {
      final centres = SupportChatResponder.replyTo('Where can I find nearby welfare centres?');
      expect(centres, contains('Open Nearest Welfare Centers'));
      expect(centres, contains('25 km'));
    });

    test('answers support helpline and calling questions', () {
      final call = SupportChatResponder.replyTo('Can I call live support?');
      expect(call, contains('+91 98765 43210'));
      expect(call, contains('admin@foodlink.org'));
    });

    test('answers open-ended and broad questions gracefully', () {
      final broadQuestion = SupportChatResponder.replyTo('What should I do if I have surplus groceries?');
      expect(broadQuestion.isNotEmpty, isTrue);
      expect(broadQuestion.toLowerCase(), contains('food'));
    });
  });

  group('SupportChatScreen Widget Tests', () {
    testWidgets('renders Mia agent header and online status badge', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SupportChatScreen()));

      expect(find.text('Mia'), findsWidgets);
      expect(find.text('LIVE AGENT'), findsOneWidget);
      expect(find.textContaining('Online'), findsOneWidget);
      expect(find.textContaining('Connected with'), findsOneWidget);
      expect(find.byTooltip('Call support'), findsOneWidget);
      expect(find.byTooltip('Start new chat'), findsOneWidget);
      expect(find.byTooltip('Speak your question'), findsOneWidget);
      expect(find.byTooltip('Send message'), findsOneWidget);
    });

    testWidgets('asking who are you returns Mia live agent intro', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SupportChatScreen()));

      await tester.enterText(find.byType(TextField), 'Who are you?');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pump();

      expect(find.textContaining("I'm Mia, your dedicated live support agent"), findsOneWidget);
    });

    testWidgets('tapping quick action chip triggers live agent response', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SupportChatScreen()));

      await tester.tap(find.text('Donate food'));
      await tester.pump();

      expect(find.textContaining('Open Donate'), findsOneWidget);
    });
  });
}
