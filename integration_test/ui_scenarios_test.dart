import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:beautydiary/main.dart' as app;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Сценарій 1: Навігація між днями', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Open overflow menu and seed sample data
    final more = find.byIcon(Icons.more_vert);
    expect(more, findsOneWidget);
    await tester.tap(more);
    await tester.pumpAndSettle();

    final seed = find.text('Додати приклади даних');
    expect(seed, findsOneWidget);
    await tester.tap(seed);
    await tester.pumpAndSettle();
    // allow DB insertion and UI update
    await tester.pump(const Duration(seconds: 1));

    // Verify seeded appointment for today appears (sample includes 'Anna' for today)
    final today = DateTime.now().day.toString();
    final dayCellFinder = find.text(today).first;
    await tester.ensureVisible(dayCellFinder);
    await tester.tap(dayCellFinder);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Anna'), findsOneWidget);
  });

  testWidgets('Сценарій 2: Кнопка "+" відкриває форму нового запису', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Try to find FontAwesome plus first, else fallback to FAB type
    final faAdd = find.byIcon(FontAwesomeIcons.plus);
    if (faAdd.evaluate().isNotEmpty) {
      await tester.tap(faAdd);
    } else {
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
    }
    await tester.pumpAndSettle();

    // Check presence of name field label
    expect(find.text('Імʼя клієнта'), findsOneWidget);
  });

  testWidgets('Сценарій 3: Валідація введення телефону', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Open new appointment form
    final faAdd2 = find.byIcon(FontAwesomeIcons.plus);
    if (faAdd2.evaluate().isNotEmpty) {
      await tester.tap(faAdd2);
    } else {
      await tester.tap(find.byType(FloatingActionButton));
    }
    await tester.pumpAndSettle();

    // Fill name and an invalid short phone
    final name = find.byType(TextFormField).at(0);
    final phone = find.byType(TextFormField).at(1);
    await tester.enterText(name, 'Тест Клієнт');
    await tester.enterText(phone, '123');
    await tester.pumpAndSettle();

    // Tap save
    final save = find.text('Зберегти');
    await tester.tap(save);
    await tester.pumpAndSettle();

    // Expect validation error about digits
    expect(find.textContaining('Потрібно'), findsOneWidget);
  });

  testWidgets('Сценарій 4: Естетика та стандарти на екрані статистики', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Open stats screen via AppBar icon
    // Try to find the FaIcon for chart inside the AppBar and tap it
    final chartIcon = find.descendant(of: find.byType(AppBar), matching: find.byIcon(FontAwesomeIcons.chartSimple));
    if (chartIcon.evaluate().isNotEmpty) {
      await tester.tap(chartIcon);
      } else {
        final iconButtons = find.byType(IconButton);
        expect(iconButtons, findsWidgets);
        await tester.tap(iconButtons.at(0));
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // If tapping did not navigate (some devices/layouts), push route directly
      if (find.text('Фінансова статистика').evaluate().isEmpty) {
        final nav = tester.state<NavigatorState>(find.byType(Navigator));
        nav.pushNamed('/stats');
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Verify stats screen elements
      expect(find.text('Фінансова статистика'), findsOneWidget);
      expect(find.textContaining('Доходи'), findsOneWidget);
  });
}
