import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'db_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  static const _channel = MethodChannel('beautydiary/backup');

  Future<String> backupNow({bool toIcloud = false}) async {
    try {
      final items = await DBService().allAppointments();
      final list = items.map((a) => a.toMap()).toList();
      final jsonStr = jsonEncode({'generatedAt': DateTime.now().toIso8601String(), 'appointments': list});

      final dir = await getApplicationDocumentsDirectory();
      final backupsDir = Directory(p.join(dir.path, 'backups'));
      if (!await backupsDir.exists()) await backupsDir.create(recursive: true);
      final file = File(p.join(backupsDir.path, 'backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json'));
      await file.writeAsString(jsonStr);

      if (toIcloud && defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          await _channel.invokeMethod('backupToICloud', {'path': file.path});
          return 'Backup saved locally and synced to iCloud: ${file.path}';
        } catch (e) {
          return 'Local backup saved but iCloud sync failed: $e';
        }
      }

      return 'Local backup saved: ${file.path}';
    } catch (e) {
      return 'Backup failed: $e';
    }
  }
}
