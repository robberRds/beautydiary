import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:beautydiary/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create appointment flow', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Open new appointment screen via FAB
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // Fill form fields: order in form is name, phone, price, note
    final fields = find.byType(TextFormField);
    // Ensure we have at least 4 form fields (name, phone, price, note)
    expect(tester.widgetList(fields).length, greaterThanOrEqualTo(4));

    await tester.enterText(fields.at(0), 'Test Klient');
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(1), '0990001111');
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(2), '350');
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(3), 'Integration test appointment');
    await tester.pumpAndSettle();

    // Save
    final saveBtn = find.text('Зберегти');
    expect(saveBtn, findsOneWidget);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    // Verify the appointment appears on the home screen list
    expect(find.text('Test Klient'), findsOneWidget);
  });
}
