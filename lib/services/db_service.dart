import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment.dart';
import 'backup_service.dart';
import 'notification_service.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'beautydiary.db');
    return await openDatabase(path, version: 2, onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE appointments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          clientName TEXT NOT NULL,
          dateTime TEXT NOT NULL,
          phone TEXT,
          price REAL,
          note TEXT,
          photoPath TEXT
        )
      ''');
    }, onUpgrade: (db, oldV, newV) async {
      if (oldV < 2) {
        // add photoPath column for migration from version 1
        await db.execute('ALTER TABLE appointments ADD COLUMN photoPath TEXT');
      }
    });
  }

  Future<int> insertAppointment(Appointment a) async {
    final database = await db;
    final res = await database.insert('appointments', a.toMap());
    unawaited(_maybeBackup());
    unawaited(NotificationService().rescheduleAll());
    return res;
  }

  Future<int> updateAppointment(Appointment a) async {
    final database = await db;
    if (a.id == null) {
      final id = await insertAppointment(a);
      return id;
    }
    final res = await database.update('appointments', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
    unawaited(_maybeBackup());
    unawaited(NotificationService().rescheduleAll());
    return res;
  }

  Future<int> deleteAppointment(int id) async {
    final database = await db;
    final res = await database.delete('appointments', where: 'id = ?', whereArgs: [id]);
    unawaited(_maybeBackup());
    unawaited(NotificationService().rescheduleAll());
    return res;
  }

  // Trigger backup after mutating operations if auto-backup enabled
  Future<void> _maybeBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final auto = prefs.getBool('autoBackup') ?? false;
      if (!auto) return;
      final icl = prefs.getBool('icloudSync') ?? false;
      // run but don't await to avoid blocking DB operations
      BackupService().backupNow(toIcloud: icl);
    } catch (_) {}
  }

  Future<int> deleteAllAppointments() async {
    final database = await db;
    final res = await database.delete('appointments');
    unawaited(_maybeBackup());
    unawaited(NotificationService().rescheduleAll());
    return res;
  }

  Future<List<Appointment>> appointmentsForDay(DateTime day) async {
    final database = await db;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(Duration(days: 1));
    final maps = await database.query('appointments',
        where: 'dateTime >= ? AND dateTime < ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'dateTime ASC');
    return maps.map((m) => Appointment.fromMap(m)).toList();
  }

  Future<List<Appointment>> allAppointments() async {
    final database = await db;
    final maps = await database.query('appointments', orderBy: 'dateTime ASC');
    return maps.map((m) => Appointment.fromMap(m)).toList();
  }

  Future<bool> hasConflict(DateTime candidate, int minutesInterval, {int? ignoreId}) async {
    final database = await db;
    final from = candidate.subtract(Duration(minutes: minutesInterval));
    final to = candidate.add(Duration(minutes: minutesInterval));
    String where = 'dateTime > ? AND dateTime < ?';
    final args = <Object?>[from.toIso8601String(), to.toIso8601String()];
    if (ignoreId != null) {
      where += ' AND id != ?';
      args.add(ignoreId);
    }
    final maps = await database.query('appointments', where: where, whereArgs: args);
    return maps.isNotEmpty;
  }

  Future<double> sumPricesBetween(DateTime from, DateTime to) async {
    final database = await db;
    final res = await database.rawQuery(
        'SELECT SUM(price) as total FROM appointments WHERE dateTime >= ? AND dateTime < ?',
        [from.toIso8601String(), to.toIso8601String()]);
    final val = res.first['total'];
    if (val == null) return 0.0;
    return (val as num).toDouble();
  }
}
