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
  final _priceCtl = TextEditingController();
  double minPrice = 0.0;
  int phoneDigits = 10;
  final _phoneDigitsCtl = TextEditingController();

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
      minPrice = prefs.getDouble('minPrice') ?? 0.0;
      _priceCtl.text = minPrice.toStringAsFixed(2);
      phoneDigits = prefs.getInt('phoneDigits') ?? 10;
      _phoneDigitsCtl.text = phoneDigits.toString();
    });
  }

  Future<void> _save() async {
    final v = int.tryParse(_ctl.text) ?? minInterval;
    final p = double.tryParse(_priceCtl.text) ?? minPrice;
    final pd = int.tryParse(_phoneDigitsCtl.text) ?? phoneDigits;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('minInterval', v);
    await prefs.setDouble('minPrice', p);
    await prefs.setInt('phoneDigits', pd);
    setState(() {
      minInterval = v;
      minPrice = p;
      phoneDigits = pd;
    });
    if (!mounted) return;
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
          TextField(controller: _priceCtl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Мінімальна ціна запису')),
          const SizedBox(height: 12),
          TextField(controller: _phoneDigitsCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Кількість цифр у телефоні (наприклад 10)')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _save, child: const Text('Зберегти'))
        ]),
      ),
    );
  }
}
