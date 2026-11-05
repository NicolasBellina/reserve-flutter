import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:reserve/data/lot_repository.dart';
import 'package:reserve/models/food_lot.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'fake_repository.dart';

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late String path;
  late SqliteLotRepository repo;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('reserve-test-');
    path = '${dir.path}/lots.db';
    repo = SqliteLotRepository(factory: databaseFactoryFfi, databasePath: path);
  });
  tearDown(() async {
    await repo.close();
    await dir.delete(recursive: true);
  });
  test('CRUD SQLite persiste après fermeture et réouverture', () async {
    expect(await repo.all(), isEmpty);
    await repo.save(example(name: "L'ail ; DROP TABLE lots"));
    await repo.close();
    final initial = (await repo.all()).single;
    await repo.save(
      initial.withStatus(LotStatus.consumed, DateTime.utc(2026, 11, 5)),
    );
    await repo.close();
    final edited = (await repo.all()).single;
    expect(edited.id, initial.id);
    expect(edited.createdAt, initial.createdAt);
    expect(edited.status, LotStatus.consumed);
    expect(edited.updatedAt, DateTime.utc(2026, 11, 5));
    await repo.delete(edited.id);
    await repo.close();
    expect(await repo.all(), isEmpty);
  });
  test(
    'fusion atomique : erreur SQL annule aussi les premières lignes',
    () async {
      await repo.all();
      final db = await databaseFactoryFfi.openDatabase(path);
      await db.execute(
        "CREATE TRIGGER fail_import BEFORE INSERT ON lots WHEN NEW.name = 'Échec' BEGIN SELECT RAISE(ABORT, 'simulation'); END",
      );
      await expectLater(
        repo.merge([
          example(),
          example(id: 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb', name: 'Échec'),
        ]),
        throwsA(isA<Exception>()),
      );
      expect(await repo.all(), isEmpty);
    },
  );
  test(
    'fusion sur disque ne duplique pas et ignore les versions anciennes',
    () async {
      await repo.save(example(updated: DateTime.utc(2026, 11, 5)));
      await repo.merge([example(name: 'Ancien')]);
      expect((await repo.all()).single.name, 'Yaourts');
      await repo.merge([
        example(name: 'Nouveau', updated: DateTime.utc(2026, 11, 6)),
      ]);
      await repo.close();
      expect((await repo.all()).single.name, 'Nouveau');
    },
  );
}
