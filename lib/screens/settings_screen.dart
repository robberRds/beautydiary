import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/backup_service.dart';
import 'notification_settings_screen.dart';

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
  bool autoBackup = false;
  bool icloudSync = false;

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
      autoBackup = prefs.getBool('autoBackup') ?? false;
      icloudSync = prefs.getBool('icloudSync') ?? false;
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
    await prefs.setBool('autoBackup', autoBackup);
    await prefs.setBool('icloudSync', icloudSync);
    setState(() {
      minInterval = v;
      minPrice = p;
      phoneDigits = pd;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Збережено')));
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
          ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())), child: const Text('Налаштування нагадувань')),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Автоматичне резервне копіювання'),
            value: autoBackup,
            onChanged: (v) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('autoBackup', v);
              setState(() => autoBackup = v);
            },
          ),
          SwitchListTile(
            title: const Text('Синхронізація з iCloud (iOS)'),
            value: icloudSync,
            onChanged: (v) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('icloudSync', v);
              setState(() => icloudSync = v);
            },
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffold = ScaffoldMessenger.of(context);
              scaffold.showSnackBar(const SnackBar(content: Text('Розпочато резервне копіювання...')));
              final res = await BackupService().backupNow(toIcloud: icloudSync);
              if (!mounted) return;
              scaffold.showSnackBar(SnackBar(content: Text(res)));
            },
            child: const Text('Резервне копіювання зараз'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _save, child: const Text('Зберегти'))
        ]),
      ),
    );
  }
}
