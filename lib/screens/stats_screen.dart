import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// dart:math removed (no longer needed)
import '../services/db_service.dart';
import '../models/appointment.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  DateTimeRange range = DateTimeRange(start: DateTime.now(), end: DateTime.now());
  double total = 0.0;
  List<Appointment> items = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    range = DateTimeRange(start: DateTime(now.year, now.month, now.day), end: DateTime(now.year, now.month, now.day).add(const Duration(days:1)));
    _load();
  }

  Future<void> _load() async {
    final s = await DBService().sumPricesBetween(range.start, range.end);
    final all = await DBService().allAppointments();
    final filtered = all.where((a) => a.dateTime.isAfter(range.start.subtract(const Duration(seconds:1))) && a.dateTime.isBefore(range.end.add(const Duration(seconds:1)))).toList();
    setState(() {
      total = s;
      items = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd().add_Hm();
    return Scaffold(
      appBar: AppBar(title: const Text('Фінансова статистика'), actions: [
        IconButton(icon: const Icon(Icons.pie_chart_outline), tooltip: 'Показати діаграми', onPressed: () => _buildCharts(context))
      ]),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(children: [
              ElevatedButton(onPressed: () async {
                final picked = await showDateRangePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2100), initialDateRange: range);
                if (picked != null) {
                  range = picked;
                  await _load();
                }
              }, child: const Text('Вибрати період')),
              const SizedBox(width: 12),
              Text('Доходи: ${total.toStringAsFixed(2)}₴', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
            ]),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft, child: Text('Період: ${df.format(range.start)} — ${df.format(range.end.subtract(const Duration(seconds:1)))}')),
            const SizedBox(height: 20),
            Expanded(child: _buildChart())
          ],
        ),
      ),
    );
  }
 
  
  Widget _buildChart() {
    if (items.isEmpty) return const Center(child: Text('No records in range'));

    final dayDf = DateFormat.yMMMd();
    final timeDf = DateFormat.Hm();

    final Map<DateTime, List<Appointment>> grouped = {};
    for (final a in items) {
      final d = DateTime(a.dateTime.year, a.dateTime.month, a.dateTime.day);
      grouped.putIfAbsent(d, () => []).add(a);
    }

    final days = grouped.keys.toList()..sort();

    final children = <Widget>[];
    for (final day in days) {
      final dayItems = grouped[day] ?? [];
      dayItems.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      final double dayTotal = dayItems.fold<double>(0.0, (s, a) => s + (a.price ?? 0.0));

      children.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Text('${dayDf.format(day)} — ${dayTotal.toStringAsFixed(2)}₴', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ));
      children.add(Padding(
        padding: const EdgeInsets.only(left: 8.0, bottom: 6.0),
        child: Text('Кількість записів: ${dayItems.length}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
      ));
      for (final a in dayItems) {
        children.add(ListTile(
          title: Text(a.clientName),
          subtitle: Text('${timeDf.format(a.dateTime)} — ${a.note ?? ''}'),
          trailing: Text(a.price == null ? '' : a.price!.toStringAsFixed(2)),
        ));
        children.add(const Divider(height: 1));
      }
    }

    return ListView(children: children);
  }

  void _buildCharts(BuildContext context) {
    final byClient = <String, double>{};
    final byDay = <DateTime, double>{};
    for (final a in items) {
      final client = a.clientName;
      final p = a.price ?? 0.0;
      byClient[client] = (byClient[client] ?? 0.0) + p;
      final d = DateTime(a.dateTime.year, a.dateTime.month, a.dateTime.day);
      byDay[d] = (byDay[d] ?? 0.0) + p;
    }

    final dayData = byDay.entries.map((e) => ChartData(label: DateFormat.Md().format(e.key), value: e.value)).toList()..sort((a,b) => a.label.compareTo(b.label));

      showDialog<void>(context: context, builder: (c) {
        return AlertDialog(
          title: const Text('Гістограма по днях'),
          content: SizedBox(
            width: 700,
            height: 420,
            child: Column(children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(children: [
                    Expanded(
                      flex: 3,
                      child: CustomPaint(
                        painter: BarChartPainter(dayData),
                        child: Container(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      flex: 2,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: dayData.map((d) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Text('${d.label}: ${d.value.toStringAsFixed(0)}'),
                          )).toList(),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Закрити'))],
        );
      });
  }

}

class ChartData {
  final String label;
  final double value;
  ChartData({required this.label, required this.value});
}

// Pie chart removed — using only BarChartPainter

class BarChartPainter extends CustomPainter {
  final List<ChartData> data;
  BarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blue;
    final padding = 8.0;
    final chartHeight = size.height - 40;
    double maxVal = 0.0;
    for (final d in data) {
      if (d.value > maxVal) maxVal = d.value;
    }
    final barWidth = (size.width - padding * 2) / (data.isEmpty ? 1 : data.length) * 0.6;
    for (var i = 0; i < data.length; i++) {
      final x = padding + i * (barWidth / 0.6);
      final h = maxVal == 0.0 ? 0.0 : (data[i].value / maxVal) * chartHeight;
      final rect = Rect.fromLTWH(x, size.height - h - 20, barWidth, h);
      canvas.drawRect(rect, paint);
      // labels rendered as widgets under chart
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
