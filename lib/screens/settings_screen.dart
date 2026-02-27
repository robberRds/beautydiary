import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int minInterval = 60;
  final _ctl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      minInterval = prefs.getInt('minInterval') ?? 60;
      _ctl.text = minInterval.toString();
    });
  }

  Future<void> _save() async {
    final v = int.tryParse(_ctl.text) ?? minInterval;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('minInterval', v);
    setState(() => minInterval = v);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Налаштування')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          TextField(controller: _ctl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Мінімальний інтервал між записами (хв)')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _save, child: const Text('Зберегти'))
        ]),
      ),
    );
  }
}
