import 'dart:math';

enum StoragePlace {
  fridge('Réfrigérateur'),
  freezer('Congélateur'),
  cupboard('Placard');

  const StoragePlace(this.label);
  final String label;
}

enum LotStatus {
  available('En stock'),
  consumed('Consommé'),
  discarded('Jeté');

  const LotStatus(this.label);
  final String label;
}

const units = ['pièce(s)', 'g', 'kg', 'ml', 'L'];
String newId() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String displayDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

/// Un lot est une quantité d'un aliment ayant la même date et le même lieu.
class FoodLot {
  FoodLot({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.place,
    required this.status,
    required this.expiry,
    required this.createdAt,
    required this.updatedAt,
    this.notes = '',
  }) {
    if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(id) ||
        name.trim().isEmpty ||
        name.length > 80 ||
        quantity < 1 ||
        quantity > 999999 ||
        !units.contains(unit) ||
        notes.length > 1000 ||
        expiry.year < 2000 ||
        expiry.year > 2100 ||
        updatedAt.isBefore(createdAt)) {
      throw const FormatException(
        'Un lot contient des informations invalides.',
      );
    }
  }
  final String id, name, unit, notes;
  final int quantity;
  final StoragePlace place;
  final LotStatus status;
  final DateTime expiry, createdAt, updatedAt;

  int daysLeft(DateTime now) => DateTime.utc(
    expiry.year,
    expiry.month,
    expiry.day,
  ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
  bool dueSoon(DateTime now) =>
      status == LotStatus.available && daysLeft(now) >= 0 && daysLeft(now) <= 3;
  String expiryLabel(DateTime now) {
    final days = daysLeft(now);
    if (days < 0) return 'Date dépassée de ${-days} j';
    if (days == 0) return "Date aujourd'hui";
    if (days == 1) return 'Date demain';
    return 'Dans $days jours';
  }

  FoodLot withStatus(LotStatus value, DateTime now) => FoodLot(
    id: id,
    name: name,
    quantity: quantity,
    unit: unit,
    place: place,
    status: value,
    expiry: expiry,
    createdAt: createdAt,
    updatedAt: now,
    notes: notes,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'place': place.name,
    'status': status.name,
    'expiry': dateKey(expiry),
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'notes': notes,
  };

  factory FoodLot.fromMap(Map<String, Object?> map) {
    try {
      final expiryText = map['expiry'] as String;
      final expiry = DateTime.parse(expiryText);
      if (dateKey(expiry) != expiryText) throw const FormatException();
      return FoodLot(
        id: map['id'] as String,
        name: (map['name'] as String).trim(),
        quantity: map['quantity'] as int,
        unit: map['unit'] as String,
        place: StoragePlace.values.byName(map['place'] as String),
        status: LotStatus.values.byName(map['status'] as String),
        expiry: expiry,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        notes: map['notes'] as String,
      );
    } on Object {
      throw const FormatException(
        'Un lot contient des informations invalides.',
      );
    }
  }
}
