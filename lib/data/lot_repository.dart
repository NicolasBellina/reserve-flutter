import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/food_lot.dart';

abstract class LotRepository {
  Future<List<FoodLot>> all();
  Future<void> save(FoodLot lot);
  Future<void> delete(String id);

  /// Fusion atomique : seuls les lots absents ou plus récents sont importés.
  Future<void> merge(List<FoodLot> lots);
  Future<void> close();
}

class SqliteLotRepository implements LotRepository {
  SqliteLotRepository({DatabaseFactory? factory, this.databasePath})
    : factory = factory ?? databaseFactory;
  final DatabaseFactory factory;
  final String? databasePath;
  Database? _database;
  Future<Database>? _opening;
  Future<Database> _open() async {
    if (_database != null) return _database!;
    if (_opening != null) return _opening!;
    final pending = _openDatabase();
    _opening = pending;
    try {
      return _database = await pending;
    } finally {
      _opening = null;
    }
  }

  Future<Database> _openDatabase() async => factory.openDatabase(
    databasePath ?? p.join(await factory.getDatabasesPath(), 'reserve.db'),
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute("""CREATE TABLE lots (
        id TEXT PRIMARY KEY, name TEXT NOT NULL,
        quantity INTEGER NOT NULL CHECK(quantity > 0 AND quantity <= 999999),
        unit TEXT NOT NULL, place TEXT NOT NULL, status TEXT NOT NULL,
        expiry TEXT NOT NULL, created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL, notes TEXT NOT NULL)""");
        await db.execute('CREATE INDEX lots_expiry ON lots(expiry)');
      },
    ),
  );
  @override
  Future<List<FoodLot>> all() async => (await (await _open()).query(
    'lots',
    orderBy: 'expiry ASC, name COLLATE NOCASE ASC',
  )).map(FoodLot.fromMap).toList();
  @override
  Future<void> save(FoodLot lot) async {
    await (await _open()).insert(
      'lots',
      lot.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(String id) async {
    await (await _open()).delete('lots', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> merge(List<FoodLot> lots) async {
    final db = await _open();
    await db.transaction((txn) async {
      for (final lot in lots) {
        final old = await txn.query(
          'lots',
          columns: ['updated_at'],
          where: 'id = ?',
          whereArgs: [lot.id],
        );
        if (old.isEmpty ||
            lot.updatedAt.isAfter(
              DateTime.parse(old.first['updated_at'] as String),
            )) {
          await txn.insert(
            'lots',
            lot.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  @override
  Future<void> close() async {
    final pending = _opening;
    if (pending != null) await pending;
    await _database?.close();
    _database = null;
  }
}
