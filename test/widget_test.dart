// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:axeguide/main.dart';

void main() {
  testWidgets('App starts and displays provided startScreen', (
    WidgetTester tester,
  ) async {
    // Build our app with a simple startScreen and trigger a frame.
    await tester.pumpWidget(
      const MyApp(
        startScreen: Scaffold(body: Center(child: Text('Start Screen'))),
      ),
    );

    // Verify that the startScreen is displayed.
    expect(find.text('Start Screen'), findsOneWidget);
  });
}
