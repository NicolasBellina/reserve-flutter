import 'dart:async';
import 'package:reserve/data/lot_repository.dart';
import 'package:reserve/models/food_lot.dart';

FoodLot example({
  String id = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  String name = 'Yaourts',
  int quantity = 4,
  LotStatus status = LotStatus.available,
  DateTime? expiry,
  DateTime? updated,
}) => FoodLot(
  id: id,
  name: name,
  quantity: quantity,
  unit: 'pièce(s)',
  place: StoragePlace.fridge,
  status: status,
  expiry: expiry ?? DateTime(2026, 11, 7),
  createdAt: DateTime.utc(2026, 11, 1),
  updatedAt: updated ?? DateTime.utc(2026, 11, 1),
  notes: 'Nature',
);

class FakeRepository implements LotRepository {
  FakeRepository([List<FoodLot>? initial]) : items = [...?initial];
  List<FoodLot> items;
  bool failRead = false, failWrite = false;
  Completer<void>? blocker;
  void checkWrite() {
    if (failWrite) throw StateError('disque plein simulé');
  }

  @override
  Future<List<FoodLot>> all() async {
    await blocker?.future;
    if (failRead) throw StateError('lecture simulée');
    return [...items];
  }

  @override
  Future<void> save(FoodLot lot) async {
    checkWrite();
    items = [...items.where((e) => e.id != lot.id), lot];
  }

  @override
  Future<void> delete(String id) async {
    checkWrite();
    items.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> merge(List<FoodLot> lots) async {
    checkWrite();
    for (final lot in lots) {
      final old = items.where((e) => e.id == lot.id);
      if (old.isEmpty || lot.updatedAt.isAfter(old.first.updatedAt)) {
        items = [...items.where((e) => e.id != lot.id), lot];
      }
    }
  }

  @override
  Future<void> close() async {}
}
