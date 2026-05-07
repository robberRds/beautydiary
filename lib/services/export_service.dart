import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import '../models/appointment.dart';

class ExportService {
  Future<String> exportAppointmentsToPdf(List<Appointment> items) async {
    final doc = pw.Document();
    final df = DateFormat('yyyy-MM-dd HH:mm');
    doc.addPage(pw.MultiPage(build: (c) {
      return [
        pw.Header(level: 0, child: pw.Text('Записи')),
        pw.TableHelper.fromTextArray(
          headers: ['Дата', 'Клієнт', 'Телефон', 'Ціна', 'Опис', 'Фото'],
          data: items
            .map((a) => [
                df.format(a.dateTime),
                a.clientName,
                a.phone ?? '',
                a.price == null ? '' : (a.price! % 1 == 0 ? '${a.price!.toStringAsFixed(0)}₴' : '${a.price!.toStringAsFixed(2)}₴'),
                a.note ?? '',
                a.photoPath ?? ''
              ])
            .toList())
      ];
    }));

    final bytes = await doc.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/appointments_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    try {
      await Printing.sharePdf(bytes: bytes, filename: file.path.split(Platform.pathSeparator).last);
    } catch (_) {}
    return file.path;
  }

  Future<String> exportAppointmentsToExcel(List<Appointment> items) async {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet()!;
    final sheet = excel[sheetName];
    sheet.appendRow(['Дата', 'Клієнт', 'Телефон', 'Ціна', 'Опис', 'Фото']);
    final df = DateFormat('yyyy-MM-dd HH:mm');
    for (final a in items) {
      final priceStr = a.price == null ? '' : (a.price! % 1 == 0 ? a.price!.toStringAsFixed(0) + '₴' : a.price!.toStringAsFixed(2) + '₴');
      sheet.appendRow([df.format(a.dateTime), a.clientName, a.phone ?? '', priceStr, a.note ?? '', a.photoPath ?? '']);
    }
    final bytes = excel.encode();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/appointments_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    if (bytes != null) await file.writeAsBytes(bytes);
    return file.path;
  }
}
