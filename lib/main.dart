import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/new_appointment_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/visit_history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('uk');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.light();
    final theme = base.copyWith(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.grey,
        brightness: Brightness.light,
        primary: Colors.grey.shade900,
        onPrimary: Colors.white,
        background: Colors.white,
        surface: Colors.grey.shade100,
      ),
      appBarTheme: AppBarTheme(backgroundColor: Colors.grey.shade900, foregroundColor: Colors.white),
      scaffoldBackgroundColor: Colors.grey.shade50,
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: Colors.grey.shade900),
      textTheme: base.textTheme.apply(bodyColor: Colors.black87, displayColor: Colors.black87),
    );

    return MaterialApp(
      title: 'Beauty Diary',
      theme: theme.copyWith(floatingActionButtonTheme: theme.floatingActionButtonTheme.copyWith(foregroundColor: Colors.white)),
      locale: const Locale('uk'),
      supportedLocales: const [Locale('uk'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routes: {
        '/': (c) => const SplashScreen(),
        '/home': (c) => const HomeScreen(),
        '/history': (c) => const VisitHistoryScreen(),
        '/new': (c) => const NewAppointmentScreen(),
        '/stats': (c) => const StatsScreen(),
        '/settings': (c) => const SettingsScreen(),
      },
      initialRoute: '/',
    );
  }
}
