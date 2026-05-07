import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/db_service.dart';
import '../models/appointment.dart';

class VisitHistoryScreen extends StatefulWidget {
  const VisitHistoryScreen({super.key});

  @override
  State<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends State<VisitHistoryScreen> {
  List<Appointment> all = [];
  List<Appointment> filtered = [];
  String query = '';
  String? selectedClient;
  // pagination
  static const int _perPage = 20;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await DBService().allAppointments();
    items.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    setState(() {
      all = items;
      _applyFilter();
    });
  }

  void _applyFilter() {
    // reset paging on new filter
    _page = 0;
    if (selectedClient != null) {
      filtered = all.where((a) => a.clientName == selectedClient).toList();
    } else if (query.trim().isEmpty) {
      filtered = List.from(all);
    } else {
      final q = query.toLowerCase();
      filtered = all.where((a) => a.clientName.toLowerCase().contains(q)).toList();
    }
    setState(() {});
  }

  Map<DateTime, List<Appointment>> _groupByDay(List<Appointment> items) {
    final Map<DateTime, List<Appointment>> map = {};
    for (final a in items) {
      final d = DateTime(a.dateTime.year, a.dateTime.month, a.dateTime.day);
      map.putIfAbsent(d, () => []).add(a);
    }
    return map;
  }

  List<String> _matchingClients() {
    final set = <String>{};
    for (final a in all) {
      if (a.clientName.toLowerCase().contains(query.toLowerCase())) set.add(a.clientName);
    }
    final list = set.toList()..sort();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final dateDf = DateFormat.yMMMd('uk');
    final timeDf = DateFormat.Hm('uk');

    // Use paged data for display
    final total = filtered.length;
    final totalPages = (total / _perPage).ceil().clamp(1, 9999);
    final start = (_page * _perPage).clamp(0, total);
    final end = ((start + _perPage) > total) ? total : (start + _perPage);
    final pageItems = filtered.sublist(start, end);
    final grouped = _groupByDay(pageItems);
    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final matchedClients = query.trim().isEmpty ? <String>[] : _matchingClients();

    Appointment? latestForSelected;
    if (selectedClient != null) {
      if (filtered.isNotEmpty) latestForSelected = filtered.first;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Записи клієнтів')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Пошук клієнта'),
              onChanged: (v) {
                selectedClient = null;
                query = v;
                _applyFilter();
              },
            ),
            if (matchedClients.isNotEmpty && selectedClient == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (c, i) {
                      final name = matchedClients[i];
                      return ChoiceChip(
                        label: Text(name),
                        selected: false,
                        onSelected: (_) {
                          selectedClient = name;
                          query = '';
                          _applyFilter();
                        },
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: matchedClients.length,
                  ),
                ),
              ),
            if (selectedClient != null && latestForSelected != null)
              Card(
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(selectedClient ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('Останній запис: ${dateDf.format(latestForSelected.dateTime)} ${timeDf.format(latestForSelected.dateTime)}'),
                          ],
                        ),
                      ),
                      Text(latestForSelected.price == null ? '-' : '${latestForSelected.price!.toStringAsFixed(2)}₴', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            // Pagination controls
            if (filtered.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _page > 0 ? () => setState(() => _page--) : null,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Text('Сторінка ${_page + 1} з $totalPages'),
                    IconButton(
                      onPressed: (_page < totalPages - 1) ? () => setState(() => _page++) : null,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Немає записів'))
                  : ListView.builder(
                      itemCount: days.length,
                      itemBuilder: (c, idx) {
                        final day = days[idx];
                        final items = grouped[day]!..sort((a, b) => b.dateTime.compareTo(a.dateTime));
                        final dayTotal = items.fold<double>(0.0, (s, a) => s + (a.price ?? 0.0));
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                              child: Text('${dateDf.format(day)} — ${dayTotal.toStringAsFixed(2)}₴', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0, bottom: 6.0),
                              child: Text('Кількість записів: ${items.length}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                            ),
                            ...items.map((a) => Column(children: [
                                  ListTile(
                                    title: Text(a.clientName),
                                    subtitle: Text('${timeDf.format(a.dateTime)} — ${a.note ?? ''}'),
                                    trailing: Text(a.price == null ? '' : a.price!.toStringAsFixed(2)),
                                  ),
                                  const Divider(height: 1),
                                ])),
                          ],
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
