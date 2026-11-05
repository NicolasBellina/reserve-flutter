import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:reserve/models/food_lot.dart';
import 'package:reserve/state/pantry_controller.dart';
import 'fake_repository.dart';

void main() {
  late FakeRepository repo;
  late PantryController c;
  setUp(() {
    repo = FakeRepository();
    c = PantryController(repo, clock: () => DateTime(2026, 11, 5));
  });
  tearDown(() => c.dispose());
  test('loading, empty et erreur récupérable', () async {
    repo.blocker = Completer<void>();
    final load = c.load();
    expect(c.state, LoadState.loading);
    repo.blocker!.complete();
    await load;
    expect(c.state, LoadState.empty);
    repo.failRead = true;
    await c.load();
    expect(c.state, LoadState.error);
    repo.failRead = false;
    await c.load();
    expect(c.state, LoadState.empty);
  });
  test('recherche sans accents combinée au filtre, bilan global', () async {
    repo.items = [
      example(name: 'Crème'),
      example(
        id: 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        status: LotStatus.consumed,
      ),
    ];
    await c.load();
    c.setQuery('creme');
    c.setFilter(LotFilter.soon);
    expect(c.visible.single.name, 'Crème');
    expect(c.consumedCount, 1);
    expect(c.soonCount, 1);
    c.setQuery('introuvable');
    expect(c.visible, isEmpty);
    expect(c.stock, hasLength(1));
  });
  test('échec écriture et suppression conservent la mémoire', () async {
    await c.load();
    repo.failWrite = true;
    expect(await c.save(example()), isFalse);
    expect(c.lots, isEmpty);
    expect(c.error, isNotNull);
    repo.failWrite = false;
    expect(await c.save(example()), isTrue);
    repo.failWrite = true;
    expect(await c.delete(example().id), isFalse);
    expect(c.lots, hasLength(1));
  });
  test('fusion idempotente privilégie modification récente', () async {
    repo.items = [example(updated: DateTime.utc(2026, 11, 4))];
    await c.load();
    final older = c.codec.encode([example(name: 'Ancien')], c.clock());
    await c.importBackup(older);
    expect(c.lots.single.name, 'Yaourts');
    final newer = c.codec.encode([
      example(name: 'Récent', updated: DateTime.utc(2026, 11, 5)),
    ], c.clock());
    await c.importBackup(newer);
    await c.importBackup(newer);
    expect(c.lots.single.name, 'Récent');
    expect(repo.items, hasLength(1));
  });
  test('import invalide ne déclenche aucune écriture', () async {
    await c.load();
    await expectLater(c.importBackup('{}'), throwsFormatException);
    expect(repo.items, isEmpty);
    expect(c.lots, isEmpty);
  });
  test('disposal pendant chargement ne notifie plus', () async {
    final repo = FakeRepository()..blocker = Completer<void>();
    final other = PantryController(repo);
    var count = 0;
    other.addListener(() => count++);
    final pending = other.load();
    other.dispose();
    repo.blocker!.complete();
    await pending;
    expect(count, 1);
  });
}
