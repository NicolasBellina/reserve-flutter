import 'dart:convert';
import '../models/food_lot.dart';

/// Format versionné, indépendant de SQLite et du sélecteur de fichiers.
class BackupCodec {
  static const maxBytes = 2 * 1024 * 1024;
  String encode(List<FoodLot> lots, DateTime now) {
    final text = const JsonEncoder.withIndent('  ').convert({
      'application': 'reserve',
      'version': 1,
      'exported_at': now.toUtc().toIso8601String(),
      'lots': lots.map((lot) => lot.toMap()).toList(),
    });
    if (utf8.encode(text).length > maxBytes || lots.length > 5000) {
      throw const FormatException(
        'Sauvegarde trop volumineuse (2 Mo ou 5 000 lots maximum).',
      );
    }
    return text;
  }

  List<FoodLot> decode(String text) {
    if (utf8.encode(text).length > maxBytes) {
      throw const FormatException('Fichier trop volumineux (2 Mo maximum).');
    }
    try {
      final data = jsonDecode(text);
      if (data is! Map<String, dynamic> ||
          data['application'] != 'reserve' ||
          data['version'] != 1 ||
          data['lots'] is! List) {
        throw const FormatException();
      }
      final rows = data['lots'] as List;
      if (rows.length > 5000) throw const FormatException();
      final ids = <String>{};
      return rows.map((row) {
        if (row is! Map<String, dynamic>) throw const FormatException();
        final lot = FoodLot.fromMap(row);
        if (!ids.add(lot.id)) throw const FormatException();
        return lot;
      }).toList();
    } on Object {
      throw const FormatException(
        'Sauvegarde invalide : format Réserve v1 attendu, lots valides et identifiants uniques.',
      );
    }
  }
}
