class Appointment {
  int? id;
  final String clientName;
  final DateTime dateTime;
  final String? phone;
  final double? price;
  final String? note;
  final String? photoPath;

  Appointment({
    this.id,
    required this.clientName,
    required this.dateTime,
    this.phone,
    this.price,
    this.note,
    this.photoPath,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'clientName': clientName,
      'dateTime': dateTime.toIso8601String(),
      'phone': phone,
      'price': price,
      'note': note,
      'photoPath': photoPath,
    };
  }

  static Appointment fromMap(Map<String, Object?> m) {
    return Appointment(
      id: m['id'] as int?,
      clientName: m['clientName'] as String,
      dateTime: DateTime.parse(m['dateTime'] as String),
      phone: m['phone'] as String?,
      price: m['price'] == null ? null : (m['price'] as num).toDouble(),
      note: m['note'] as String?,
      photoPath: m['photoPath'] as String?,
    );
  }
}
