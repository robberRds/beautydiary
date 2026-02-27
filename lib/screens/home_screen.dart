import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/db_service.dart';
import '../services/export_service.dart';
import '../models/appointment.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();
  Map<DateTime, List<Appointment>> events = {};

  @override
  void initState() {
    super.initState();
    _loadForMonth(_focused);
  }

  Future<void> _loadForMonth(DateTime forMonth) async {
    final db = DBService();
    final start = DateTime(forMonth.year, forMonth.month, 1);
    final end = DateTime(forMonth.year, forMonth.month + 1, 1);
    final all = await db.allAppointments();
    final map = <DateTime, List<Appointment>>{};
    for (final a in all) {
      final d = DateTime(a.dateTime.year, a.dateTime.month, a.dateTime.day);
      map.putIfAbsent(d, () => []).add(a);
    }
    setState(() {
      events = map;
    });
  }

  List<Appointment> _eventsForDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return events[d] ?? [];
  }

  Future<void> _seedSampleData() async {
    final db = DBService();
    final now = DateTime.now();
    final samples = <Appointment>[
      Appointment(clientName: 'Anna', dateTime: DateTime(now.year, now.month, now.day, 10, 0), phone: '0991112233', price: 400.0, note: 'Classic manicure'),
      Appointment(clientName: 'Oksana', dateTime: DateTime(now.year, now.month, now.day, 12, 0), phone: '0992223344', price: 500.0, note: 'Gel polish'),
      Appointment(clientName: 'Ira', dateTime: DateTime(now.year, now.month, now.day + 1, 9, 30), phone: '0993334455', price: 350.0, note: 'Manicure + design'),
      Appointment(clientName: 'Lena', dateTime: DateTime(now.year, now.month, now.day + 2, 14, 0), phone: '0994445566', price: 450.0, note: 'Shellac'),
    ];
    for (final s in samples) {
      await db.insertAppointment(s);
    }
    await _loadForMonth(_focused);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sample data inserted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Щоденник майстра'),
        actions: [
          IconButton(
              onPressed: () => Navigator.pushNamed(context, '/stats'),
              icon: const Icon(Icons.bar_chart)),
          IconButton(
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              icon: const Icon(Icons.settings)),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'pdf') {
                final all = await DBService().allAppointments();
                final path = await ExportService().exportAppointmentsToPdf(all);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF saved: $path')));
              } else if (v == 'xlsx') {
                final all = await DBService().allAppointments();
                final path = await ExportService().exportAppointmentsToExcel(all);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excel saved: $path')));
              } else if (v == 'seed') {
                await _seedSampleData();
              }
            },
            itemBuilder: (c) => [
              const PopupMenuItem(value: 'pdf', child: Text('Експортувати PDF')),
              const PopupMenuItem(value: 'xlsx', child: Text('Експортувати Excel')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'seed', child: Text('Додати приклади даних')),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focused,
            selectedDayPredicate: (d) => isSameDay(d, _selected),
            onDaySelected: (selected, focused) async {
              setState(() {
                _selected = selected;
                _focused = focused;
              });
              await _loadForMonth(focused);
            },
            onPageChanged: (focused) async {
              _focused = focused;
              await _loadForMonth(focused);
            },
            eventLoader: (day) => _eventsForDay(day),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, eventsList) {
                final count = _eventsForDay(date).length;
                if (count == 0) return const SizedBox.shrink();
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/new', arguments: _selected);
          await _loadForMonth(_focused);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList() {
    final list = _eventsForDay(_selected);
    if (list.isEmpty) {
      return const Center(child: Text('No appointments'));
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, i) {
        final a = list[i];
        final time = DateFormat.Hm().format(a.dateTime);
        return ListTile(
          title: Text('${a.clientName} — $time'),
          subtitle: Text('${a.price == null ? '' : '${a.price}₴ — '} ${a.phone ?? ''}'),
          onTap: () async {
            await Navigator.pushNamed(context, '/new', arguments: a);
            await _loadForMonth(_focused);
          },
        );
      },
    );
  }
}

