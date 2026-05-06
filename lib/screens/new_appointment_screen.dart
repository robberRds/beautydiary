import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  double minPrice = 0.0;
  int phoneDigits = 10;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      minPrice = prefs.getDouble('minPrice') ?? 0.0;
      phoneDigits = prefs.getInt('phoneDigits') ?? 10;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)!.settings.arguments;
    if (arg is DateTime) {
      _dt = DateTime(arg.year, arg.month, arg.day, _dt.hour, _dt.minute);
    } else if (arg is Appointment) {
      final a = arg;
      _editingId = a.id;
      _nameCtl.text = a.clientName;
      _phoneCtl.text = a.phone ?? '';
      _priceCtl.text = a.price?.toString() ?? '';
      _noteCtl.text = a.note ?? '';
      _dt = a.dateTime;
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _phoneCtl.dispose();
    _priceCtl.dispose();
    _noteCtl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('uk'),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dt));
    if (time == null) return;
    if (!mounted) return;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Конфлікт з існуючим записом')));
      return;
    }
    final price = _priceCtl.text.isEmpty ? null : double.tryParse(_priceCtl.text);
    final a = Appointment(id: _editingId, clientName: _nameCtl.text.trim(), dateTime: _dt, phone: _phoneCtl.text.isEmpty ? null : _phoneCtl.text.trim(), price: price, note: _noteCtl.text.isEmpty ? null : _noteCtl.text.trim());
    if (_editingId == null) {
      await db.insertAppointment(a);
    } else {
      await db.updateAppointment(a);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (_editingId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Видалити'),
        content: const Text('Видалити цей запис?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Ні')),
          TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Так')),
        ],
      ),
    );
    if (ok == true) {
      await DBService().deleteAppointment(_editingId!);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editingId == null ? 'Новий запис' : 'Редагувати запис'), actions: _editingId != null ? [IconButton(onPressed: _delete, icon: const FaIcon(FontAwesomeIcons.trashCan))] : null),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(labelText: 'Імʼя клієнта'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Обовʼязково' : null,
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text('Час: ${DateFormat.yMMMd().add_Hm().format(_dt)}')),
                TextButton(onPressed: _pickDateTime, child: const Text('Змінити'))
              ]),
              TextFormField(
                controller: _phoneCtl,
                decoration: const InputDecoration(labelText: 'Телефон (необовʼязково)'),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length != phoneDigits) return 'Потрібно $phoneDigits цифр';
                  return null;
                },
              ),
              TextFormField(
                controller: _priceCtl,
                decoration: const InputDecoration(labelText: 'Ціна (необовʼязково)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final p = double.tryParse(v.replaceAll(',', '.'));
                  if (p == null) return 'Невірний формат ціни';
                  if (p < minPrice) return 'Мінімальна ціна: ${minPrice.toStringAsFixed(2)}';
                  return null;
                },
              ),
              TextFormField(
                controller: _noteCtl,
                decoration: const InputDecoration(labelText: 'Опис (необовʼязково)'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _save, child: const Text('Зберегти'))
            ],
          ),
        ),
      ),
    );
  }
}
