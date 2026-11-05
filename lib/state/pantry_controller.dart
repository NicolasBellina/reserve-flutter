import 'package:flutter/foundation.dart';
import '../data/lot_repository.dart';
import '../models/food_lot.dart';
import '../services/backup_codec.dart';

enum LoadState { loading, success, empty, error }

enum LotFilter {
  stock('En stock'),
  soon('Sous 3 jours'),
  expired('Date dépassée'),
  consumed('Consommés'),
  discarded('Jetés'),
  all('Tous');

  const LotFilter(this.label);
  final String label;
}

class PantryController extends ChangeNotifier {
  PantryController(this.repository, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  final LotRepository repository;
  final DateTime Function() clock;
  final codec = BackupCodec();
  List<FoodLot> _lots = [];
  LoadState state = LoadState.loading;
  String query = '';
  LotFilter filter = LotFilter.stock;
  String? error;
  bool busy = false;
  bool _disposed = false;
  List<FoodLot> get lots => List.unmodifiable(_lots);
  List<FoodLot> get stock =>
      _lots.where((e) => e.status == LotStatus.available).toList();
  int get soonCount => stock.where((e) => e.dueSoon(clock())).length;
  int get expiredCount => stock.where((e) => e.daysLeft(clock()) < 0).length;
  int get consumedCount =>
      _lots.where((e) => e.status == LotStatus.consumed).length;
  int get discardedCount =>
      _lots.where((e) => e.status == LotStatus.discarded).length;
  double get usedRatio => consumedCount + discardedCount == 0
      ? 0
      : consumedCount / (consumedCount + discardedCount);
  List<FoodLot> get visible {
    final now = clock();
    final needle = _normalize(query.trim());
    return _lots.where((e) {
      final matches = switch (filter) {
        LotFilter.stock => e.status == LotStatus.available,
        LotFilter.soon => e.dueSoon(now),
        LotFilter.expired =>
          e.status == LotStatus.available && e.daysLeft(now) < 0,
        LotFilter.consumed => e.status == LotStatus.consumed,
        LotFilter.discarded => e.status == LotStatus.discarded,
        LotFilter.all => true,
      };
      return matches &&
          _normalize('${e.name} ${e.notes} ${e.place.label}').contains(needle);
    }).toList()..sort((a, b) {
      final date = a.expiry.compareTo(b.expiry);
      return date == 0 ? a.name.compareTo(b.name) : date;
    });
  }

  String _normalize(String value) {
    var result = value.toLowerCase();
    const source = 'àâäéèêëîïôöùûüç';
    const target = 'aaaeeeeiioouuuc';
    for (var i = 0; i < source.length; i++) {
      result = result.replaceAll(source[i], target[i]);
    }
    return result;
  }

  void setQuery(String value) {
    query = value;
    _notify();
  }

  void setFilter(LotFilter value) {
    filter = value;
    _notify();
  }

  void refreshDates() => _notify();
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _setDataState() {
    state = _lots.isEmpty ? LoadState.empty : LoadState.success;
  }

  Future<void> load() async {
    if (busy) return;
    busy = true;
    state = LoadState.loading;
    error = null;
    _notify();
    try {
      _lots = await repository.all();
      _setDataState();
    } catch (e) {
      state = LoadState.error;
      error = 'Impossible de lire le garde-manger. Réessayez.';
      debugPrint('Lecture SQLite : ${e.runtimeType}');
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> _write(
    Future<void> Function() action,
    void Function() apply,
  ) async {
    if (busy || state == LoadState.error || state == LoadState.loading) {
      return false;
    }
    busy = true;
    error = null;
    _notify();
    try {
      await action();
      apply();
      _setDataState();
      return true;
    } catch (e) {
      error =
          "Enregistrement impossible. Vos données restent inchangées. Réessayez.";
      debugPrint('Écriture SQLite : ${e.runtimeType}');
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> save(FoodLot lot) => _write(() => repository.save(lot), () {
    _lots = [..._lots.where((e) => e.id != lot.id), lot];
  });
  Future<bool> delete(String id) => _write(() => repository.delete(id), () {
    _lots.removeWhere((e) => e.id == id);
  });
  String exportBackup() => codec.encode(_lots, clock());
  Future<bool> importBackup(String text) async {
    final incoming = codec.decode(
      text,
    ); // Validation complète avant toute écriture.
    return _write(() => repository.merge(incoming), () {
      final merged = {for (final lot in _lots) lot.id: lot};
      for (final lot in incoming) {
        final old = merged[lot.id];
        if (old == null || lot.updatedAt.isAfter(old.updatedAt)) {
          merged[lot.id] = lot;
        }
      }
      _lots = merged.values.toList();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
