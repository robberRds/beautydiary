import 'package:flutter_test/flutter_test.dart';
import 'package:beautydiary/models/appointment.dart';

void main() {
  test('Appointment toMap/fromMap roundtrip', () {
    final a = Appointment(
      id: 1,
      clientName: 'Тест Клієнт',
      dateTime: DateTime(2026, 3, 18, 10, 30),
      phone: '0990001111',
      price: 250.0,
      note: 'Тестовий запис',
    );

    final m = a.toMap();
    expect(m['clientName'], 'Тест Клієнт');

    final b = Appointment.fromMap(m);
    expect(b.id, 1);
    expect(b.clientName, 'Тест Клієнт');
    expect(b.dateTime, DateTime(2026, 3, 18, 10, 30));
    expect(b.phone, '0990001111');
    expect(b.price, 250.0);
    expect(b.note, 'Тестовий запис');
  });
}
