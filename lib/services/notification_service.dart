import 'dart:async';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

import 'db_service.dart';
import '../models/appointment.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    final settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);

    // On iOS/macOS request permissions explicitly (helps when plugin defaults don't trigger)
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        final iosImpl = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      debugPrint('iOS permission request error: $e');
    }

    // Create Android notification channels (idempotent)
    try {
      if (Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
          'bd_morning',
          'Morning reminders',
          description: 'Daily morning reminder',
          importance: Importance.defaultImportance,
        ));
        await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
          'bd_pre',
          'Pre-event reminders',
          description: 'Reminders before appointment',
          importance: Importance.high,
        ));
      }
    } catch (e) {
      debugPrint('Failed to create notification channels: $e');
    }

    // timezone
    tzdata.initializeTimeZones();
    // Try to set a reasonable local timezone. Prefer device timezone name
    // if available; fall back to UTC to avoid native plugin build issues.
    try {
      final name = DateTime.now().timeZoneName;
      try {
        tz.setLocalLocation(tz.getLocation(name));
      } catch (_) {
        // fallback: try common mappings for iOS (e.g., 'GMT+3' etc.)
        tz.setLocalLocation(tz.UTC);
      }
    } catch (e) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> rescheduleAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('remindersEnabled') ?? true;
      if (!enabled) {
        await cancelAll();
        return;
      }

      final morningHour = prefs.getInt('morningHour') ?? 9;
      final morningMinute = prefs.getInt('morningMinute') ?? 0;
      final preOffset = prefs.getInt('preOffsetMinutes') ?? 60;

      await cancelAll();

      // schedule today's morning summary
      await _scheduleMorningReminder(hour: morningHour, minute: morningMinute);

      // schedule pre-event reminders for upcoming appointments
      await _schedulePreEventReminders(preOffsetMinutes: preOffset);
    } catch (e) {
      debugPrint('rescheduleAll error: $e');
    }
  }

  Future<void> _scheduleMorningReminder({required int hour, required int minute}) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      // skip scheduling for past time today
    }

    // prepare payload with first appointment info
    final first = await _firstAppointmentOfDay(DateTime.now());
    final title = 'Плани на сьогодні';
    final body = first == null
        ? 'Немає записів на сьогодні'
        : '${first.clientName} о ${_formatTime(first.dateTime)} — всього ${await _countAppointmentsForDay(DateTime.now())} записів';

    try {
      await _plugin.zonedSchedule(
        1000,
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails('bd_morning', 'Morning reminders', channelDescription: 'Daily morning reminder'),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on PlatformException catch (e) {
      debugPrint('Morning schedule exact alarm failed: $e');
      // Retry with inexact mode for devices/emulators that disallow exact alarms
      await _plugin.zonedSchedule(
        1000,
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails('bd_morning', 'Morning reminders', channelDescription: 'Daily morning reminder'),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

  }

  Future<void> _schedulePreEventReminders({required int preOffsetMinutes}) async {
    final all = await DBService().allAppointments();
    final now = DateTime.now();
    for (final a in all) {
      final target = a.dateTime.subtract(Duration(minutes: preOffsetMinutes));
      if (target.isBefore(now)) continue;
      final scheduled = tz.TZDateTime.from(target, tz.local);
      final title = 'Наступний запис';
      final body = '${_formatTime(a.dateTime)} — ${a.clientName}';
      try {
        await _plugin.zonedSchedule(
          a.id ?? target.millisecondsSinceEpoch % 100000,
          title,
          body,
          scheduled,
          const NotificationDetails(
            android: AndroidNotificationDetails('bd_pre', 'Pre-event reminders', channelDescription: 'Reminders before appointment'),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } on PlatformException catch (e) {
        debugPrint('Pre-event exact alarm failed for ${a.id}: $e');
        await _plugin.zonedSchedule(
          a.id ?? target.millisecondsSinceEpoch % 100000,
          title,
          body,
          scheduled,
          const NotificationDetails(
            android: AndroidNotificationDetails('bd_pre', 'Pre-event reminders', channelDescription: 'Reminders before appointment'),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  Future<Appointment?> _firstAppointmentOfDay(DateTime day) async {
    final items = await DBService().appointmentsForDay(day);
    if (items.isEmpty) return null;
    items.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return items.first;
  }

  Future<int> _countAppointmentsForDay(DateTime day) async {
    final items = await DBService().appointmentsForDay(day);
    return items.length;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
