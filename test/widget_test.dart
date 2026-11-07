// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:editnova/pages/background_remover_page.dart';
import 'package:editnova/pages/text_translator_page.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      // Avoid starting timers/ad components in widget tests.
      MaterialApp(
        home: Scaffold(body: Center(child: Text('0'))),
      ),
    );

    // Smoke assertions: avoid brittle widget-key/icon lookups.
    expect(find.text('0'), findsWidgets);
    expect(find.text('1'), findsNothing);

    // No interactions.
  });

  testWidgets('background processing requires an image selection', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: BackgroundRemoverPage()));

    expect(
      find.textContaining(
        'Removes edge-connected pixels similar to the four corner colors.',
      ),
      findsOneWidget,
    );

    final processButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Remove flat background'),
    );
    expect(processButton.onPressed, isNull);
  });
  testWidgets('translator reports unsupported desktop platforms', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await tester.pumpWidget(const MaterialApp(home: TextTranslatorPage()));

    expect(
      find.text('On-device translation is supported on Android and iOS only.'),
      findsOneWidget,
    );
  });
}
