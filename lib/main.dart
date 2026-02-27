import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/new_appointment_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beauty Diary',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.pink),
      routes: {
        '/': (c) => const SplashScreen(),
        '/home': (c) => const HomeScreen(),
        '/new': (c) => const NewAppointmentScreen(),
        '/stats': (c) => const StatsScreen(),
        '/settings': (c) => const SettingsScreen(),
      },
      initialRoute: '/',
    );
  }
}
