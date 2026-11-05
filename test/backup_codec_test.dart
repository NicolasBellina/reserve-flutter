import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:reserve/services/backup_codec.dart';
import 'fake_repository.dart';

void main() {
  final codec = BackupCodec();
  final now = DateTime.utc(2026, 11, 5);
  test('export puis import JSON sans perte, y compris accents', () {
    final lot = example(name: 'Crème fraîche');
    expect(codec.decode(codec.encode([lot], now)).single.toMap(), lot.toMap());
    expect(codec.decode(codec.encode([], now)), isEmpty);
  });
  test('doublons, version inconnue et fichier malformé refusés', () {
    final data =
        jsonDecode(codec.encode([example()], now)) as Map<String, dynamic>;
    for (final text in [
      '{',
      '{}',
      codec.encode([example(), example()], now),
      jsonEncode({...data, 'version': 2}),
    ]) {
      expect(() => codec.decode(text), throwsFormatException);
    }
  });
  test('limite de taille vérifiée avant analyse', () {
    expect(() => codec.decode('é' * (1024 * 1024 + 1)), throwsFormatException);
  });
}
