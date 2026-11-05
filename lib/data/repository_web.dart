import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'lot_repository.dart';

LotRepository createRepository() => SqliteLotRepository(
  factory: databaseFactoryFfiWeb,
  databasePath: 'reserve.db',
);
