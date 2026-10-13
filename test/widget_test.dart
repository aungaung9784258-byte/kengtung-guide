// Smoke test for Kengtung Guide.
//
// Verifies the app boots and the Welcome screen renders.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kengtung_guide/app/app.dart';

void main() {
  testWidgets('App boots and shows the Welcome screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: KengtungGuideApp()),
    );
    await tester.pump(const Duration(seconds: 1));

    // The welcome screen shows the app name and the "Let's Tour" button.
    expect(find.text('Kengtung Guide'), findsOneWidget);
    expect(find.byType(FilledButton), findsWidgets);
  });
}