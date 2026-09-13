import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_donation_app/screens/nearest_welfare_centers_screen.dart';

void main() {
  testWidgets('nearest welfare centers screen shows sample centers', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: NearestWelfareCentersScreen()));
    await tester.pump();

    expect(find.text('Nearest Welfare Centers'), findsWidgets);
    expect(find.textContaining('drop-off center'), findsWidgets);
  });
}
