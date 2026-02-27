import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment.dart';
import '../services/db_service.dart';

class NewAppointmentScreen extends StatefulWidget {
  const NewAppointmentScreen({super.key});

  @override
  State<NewAppointmentScreen> createState() => _NewAppointmentScreenState();
}

class _NewAppointmentScreenState extends State<NewAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _priceCtl = TextEditingController();
  final _noteCtl = TextEditingController();
  DateTime _dt = DateTime.now();
  int? _editingId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)!.settings.arguments;
    if (arg is DateTime) {
      _dt = DateTime(arg.year, arg.month, arg.day, _dt.hour, _dt.minute);
    } else if (arg is Map && arg['appointment'] != null) {
      final a = arg['appointment'] as dynamic;
      if (a is! DateTime) {
        try {
          final ap = a as Object;
        } catch (_) {}
      }
    } else if (arg != null && arg is Object) {
      // support passing Appointment directly
      try {
        final ap = arg as dynamic;
        if (ap.clientName != null && ap.dateTime != null) {
          _editingId = ap.id as int?;
          _nameCtl.text = ap.clientName as String;
          _phoneCtl.text = (ap.phone ?? '') as String;
          _priceCtl.text = ap.price == null ? '' : ap.price.toString();
          _noteCtl.text = (ap.note ?? '') as String;
          _dt = ap.dateTime as DateTime;
        }
      } catch (_) {}
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
        context: context,
        initialDate: _dt,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dt));
    if (time == null) return;
    setState(() {
      _dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final prefs = await SharedPreferences.getInstance();
    final minInterval = prefs.getInt('minInterval') ?? 60;
    final db = DBService();
    final conflict = await db.hasConflict(_dt, minInterval, ignoreId: _editingId);
    if (conflict) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conflict with existing appointment')));
      return;
    }
    final price = _priceCtl.text.isEmpty ? null : double.tryParse(_priceCtl.text);
    final a = Appointment(id: _editingId, clientName: _nameCtl.text, dateTime: _dt, phone: _phoneCtl.text.isEmpty ? null : _phoneCtl.text, price: price, note: _noteCtl.text.isEmpty ? null : _noteCtl.text);
    if (_editingId == null) {
      await db.insertAppointment(a);
    } else {
      await db.updateAppointment(a);
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (_editingId == null) return;
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Delete'), content: const Text('Delete this appointment?'), actions: [TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('No')), TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Yes'))]));
    if (ok == true) {
      await DBService().deleteAppointment(_editingId!);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editingId == null ? 'New Appointment' : 'Edit Appointment'), actions: _editingId != null ? [IconButton(onPressed: _delete, icon: const Icon(Icons.delete))] : null),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(labelText: 'Client name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text('Time: ${DateFormat.yMMMd().add_Hm().format(_dt)}')),
                TextButton(onPressed: _pickDateTime, child: const Text('Change'))
              ]),
              TextFormField(controller: _phoneCtl, decoration: const InputDecoration(labelText: 'Phone (optional)')),
              TextFormField(controller: _priceCtl, decoration: const InputDecoration(labelText: 'Price (optional)'), keyboardType: TextInputType.number),
              TextFormField(controller: _noteCtl, decoration: const InputDecoration(labelText: 'Note (optional)')),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _save, child: const Text('Save'))
            ],
          ),
        ),
      ),
    );
  }
}
