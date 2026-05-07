import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/db_service.dart';
import '../models/appointment.dart';
import 'photo_viewer_screen.dart';

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  List<Appointment> _all = [];
  List<Appointment> _filtered = [];
  final _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await DBService().allAppointments();
    final photos = all.where((a) => a.photoPath != null && a.photoPath!.isNotEmpty).toList().reversed.toList();
    setState(() {
      _all = photos;
      _filtered = photos;
    });
  }

  void _applyFilter(String q) {
    final low = q.trim().toLowerCase();
    if (low.isEmpty) {
      setState(() => _filtered = _all);
      return;
    }
    setState(() {
      _filtered = _all.where((a) => a.clientName.toLowerCase().contains(low)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Галерея манікюрів')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(8.0), child: TextField(controller: _searchCtl, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Пошук за імʼям клієнта'), onChanged: _applyFilter)),
        Expanded(
          child: _filtered.isEmpty
              ? const Center(child: Text('Немає фото'))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.8, crossAxisSpacing: 8, mainAxisSpacing: 8),
                  itemCount: _filtered.length,
                  itemBuilder: (c, i) {
                    final a = _filtered[i];
                    return Card(
                      clipBehavior: Clip.hardEdge,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(children: [
                        Expanded(
                            child: a.photoPath != null
                                ? InkWell(
                                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PhotoViewerScreen(path: a.photoPath!))),
                                    child: Image.file(File(a.photoPath!), fit: BoxFit.cover, width: double.infinity),
                                  )
                                : const SizedBox.shrink()),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(a.clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(DateFormat.yMMMd('uk').format(a.dateTime)),
                            if (a.price != null) Align(alignment: Alignment.centerRight, child: Text('${a.price!.toStringAsFixed(0)}₴', style: const TextStyle(fontWeight: FontWeight.w600))),
                          ]),
                        )
                      ]),
                    );
                  },
                ),
        )
      ]),
    );
  }
}
