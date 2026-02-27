import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/appointment.dart';

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
    return await openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE appointments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          clientName TEXT NOT NULL,
          dateTime TEXT NOT NULL,
          phone TEXT,
          price REAL,
          note TEXT
        )
      ''');
    });
  }

  Future<int> insertAppointment(Appointment a) async {
    final database = await db;
    return await database.insert('appointments', a.toMap());
  }

  Future<int> updateAppointment(Appointment a) async {
    final database = await db;
    if (a.id == null) return await insertAppointment(a);
    return await database.update('appointments', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  }

  Future<int> deleteAppointment(int id) async {
    final database = await db;
    return await database.delete('appointments', where: 'id = ?', whereArgs: [id]);
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
