import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool enabled = true;
  int morningHour = 9;
  int morningMinute = 0;
  int preOffset = 60;
  bool sound = true;
  bool vibration = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      enabled = prefs.getBool('remindersEnabled') ?? true;
      morningHour = prefs.getInt('morningHour') ?? 9;
      morningMinute = prefs.getInt('morningMinute') ?? 0;
      preOffset = prefs.getInt('preOffsetMinutes') ?? 60;
      sound = prefs.getBool('reminderSound') ?? true;
      vibration = prefs.getBool('reminderVibration') ?? true;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remindersEnabled', enabled);
    await prefs.setInt('morningHour', morningHour);
    await prefs.setInt('morningMinute', morningMinute);
    await prefs.setInt('preOffsetMinutes', preOffset);
    await prefs.setBool('reminderSound', sound);
    await prefs.setBool('reminderVibration', vibration);
    await NotificationService().rescheduleAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Збережено налаштування нагадувань')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Налаштування нагадувань')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          SwitchListTile(title: const Text('Нагадування ввімкнено'), value: enabled, onChanged: (v) => setState(() => enabled = v)),
          ListTile(
            title: const Text('Ранкове нагадування'),
            subtitle: Text('Час: ${morningHour.toString().padLeft(2, '0')}:${morningMinute.toString().padLeft(2, '0')}'),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: morningHour, minute: morningMinute));
              if (t != null) setState(() { morningHour = t.hour; morningMinute = t.minute; });
            },
          ),
          ListTile(
            title: const Text('Нагадування перед записом'),
            subtitle: Text('За $preOffset хвилин'),
            onTap: () async {
              final v = await showDialog<int>(context: context, builder: (c) => SimpleDialog(children: [
                SimpleDialogOption(child: const Text('15 хв'), onPressed: () => Navigator.of(c).pop(15)),
                SimpleDialogOption(child: const Text('30 хв'), onPressed: () => Navigator.of(c).pop(30)),
                SimpleDialogOption(child: const Text('60 хв'), onPressed: () => Navigator.of(c).pop(60)),
                SimpleDialogOption(child: const Text('120 хв'), onPressed: () => Navigator.of(c).pop(120)),
              ]));
              if (v != null) setState(() { preOffset = v; });
            },
          ),
          SwitchListTile(title: const Text('Звук'), value: sound, onChanged: (v) => setState(() => sound = v)),
          SwitchListTile(title: const Text('Вібрація'), value: vibration, onChanged: (v) => setState(() => vibration = v)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _save, child: const Text('Зберегти')),
        ]),
      ),
    );
  }
}
