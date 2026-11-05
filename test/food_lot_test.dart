import 'package:flutter_test/flutter_test.dart';
import 'package:reserve/models/food_lot.dart';
import 'fake_repository.dart';

void main() {
  test('sérialisation conserve identité, quantité et dates', () {
    final lot = example();
    final restored = FoodLot.fromMap(lot.toMap());
    expect(restored.toMap(), lot.toMap());
  });
  test('dates calculées par calendrier et borne des trois jours', () {
    final now = DateTime(2026, 11, 5, 23, 59);
    expect(example(expiry: DateTime(2026, 11, 8)).dueSoon(now), isTrue);
    expect(example(expiry: DateTime(2026, 11, 9)).dueSoon(now), isFalse);
    expect(example(expiry: DateTime(2026, 11, 4)).daysLeft(now), -1);
    expect(example(status: LotStatus.consumed).dueSoon(now), isFalse);
    expect(
      example(expiry: DateTime(2026, 11, 5)).expiryLabel(now),
      "Date aujourd'hui",
    );
  });
  test('statut inconnu, quantité invalide et date normalisée rejetés', () {
    for (final map in [
      example().toMap()..['status'] = 'inconnu',
      example().toMap()..['quantity'] = 0,
      example().toMap()..['expiry'] = '2026-02-31',
    ]) {
      expect(() => FoodLot.fromMap(map), throwsFormatException);
    }
  });
  test('identifiants aléatoires stables au format attendu', () {
    final ids = List.generate(200, (_) => newId());
    expect(ids.toSet(), hasLength(200));
    expect(ids.every((e) => RegExp(r'^[a-f0-9]{32}$').hasMatch(e)), isTrue);
  });
}
