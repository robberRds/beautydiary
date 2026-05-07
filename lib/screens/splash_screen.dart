import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/db_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // load DB
    await DBService().db;
    // ensure default settings
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('minInterval')) {
      await prefs.setInt('minInterval', 60);
    }
    // small delay for splash effect
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        // show app icon on splash
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Image.asset('lib/icon/Image_m2rublm2rublm2ru.png', width: 140, height: 140),
        ),
        const SizedBox(height: 12),
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        const Text('Завантаження...')
      ])),
    );
  }
}
