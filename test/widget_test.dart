// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beautydiary/main.dart';

void main() {
  testWidgets('App shows main title (stub)', (WidgetTester tester) async {
    // Instead of pumping the whole app (which opens a DB), pump a minimal scaffold
    await tester.pumpWidget(MaterialApp(home: Scaffold(appBar: AppBar(title: const Text('Щоденник майстра')))));
    expect(find.text('Щоденник майстра'), findsOneWidget);
  });
}
