// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cradle_actual_project/main.dart';

void main() {
  testWidgets('CradleApp loads LandingPage smoke test',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CradleApp());

    // Example: Verify that the LandingPage (which shows an image initially) is present.
    // This is a very basic check and would need to be more specific.
    // For instance, you might look for a specific image asset or a key.
    // As LandingPage has a delay, you might need tester.pumpAndSettle() or pump(Duration)
    // expect(find.byType(Image), findsWidgets); // This is a generic check
    expect(find.text('Cradle'),
        findsOneWidget); // Checks for the app title in MaterialApp
  });
}
