import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Le canal Android utilise le sélecteur système, sans permission de stockage.
class DocumentService {
  static const channel = MethodChannel('fr.nicolasbellina.reserve/documents');
  bool get supportsFiles =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  Future<bool> save(String json) async =>
      await channel.invokeMethod<bool>('export', {'json': json}) ?? false;
  Future<String?> open() => channel.invokeMethod<String>('import');
}
