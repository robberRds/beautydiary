import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Фінансова статистика')),
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
              Text('Доходи: ${total.toStringAsFixed(2)}')
            ]),
            const SizedBox(height: 20),
            Expanded(child: _buildChart())
          ],
        ),
      ),
    );
  }
  Widget _buildChart() {
    if (items.isEmpty) return const Center(child: Text('No records in range'));
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (c, i) {
        final a = items[i];
        return ListTile(
          title: Text(a.clientName),
          subtitle: Text('${a.dateTime.toLocal()} - ${a.note ?? ''}'),
          trailing: Text(a.price == null ? '' : a.price!.toStringAsFixed(2)),
        );
      },
    );
  }
}
