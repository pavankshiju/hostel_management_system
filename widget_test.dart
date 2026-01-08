import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// IMPORTANT: Ensure the package name matches your pubspec.yaml name
import 'package:hostel_management_system/main.dart';

void main() {
  testWidgets('HostelApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We use HostelApp() because that is the name of the class in your main.dart
    await tester.pumpWidget(const HostelApp());

    // Verify that our app starts (usually shows a loading indicator while auth initializes)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}