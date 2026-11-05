import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/document_service.dart';
import '../state/pantry_controller.dart';
import 'widgets/common.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key, required this.controller});
  final PantryController controller;
  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final _input = TextEditingController();
  final _documents = DocumentService();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _export({bool file = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final json = widget.controller.exportBackup();
      if (file) {
        final saved = await _documents.save(json);
        if (mounted) {
          message(
            context,
            saved ? 'Sauvegarde JSON enregistrée.' : 'Export annulé.',
          );
        }
      } else {
        await Clipboard.setData(ClipboardData(text: json));
        if (mounted) {
          message(
            context,
            'Sauvegarde JSON copiée. Conservez-la dans un fichier.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is FormatException
              ? e.message
              : 'Export impossible. Réessayez ou copiez le JSON.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openFile() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final text = await _documents.open();
      if (!mounted) return;
      if (text != null) {
        _input.text = text;
        await _previewAndImport(text);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Lecture du fichier impossible. Choisissez un JSON Réserve de moins de 2 Mo.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importText() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _previewAndImport(_input.text);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _previewAndImport(String text) async {
    try {
      final incoming = widget.controller.codec.decode(text);
      final current = {for (final lot in widget.controller.lots) lot.id: lot};
      final added = incoming
          .where((lot) => !current.containsKey(lot.id))
          .length;
      final updated = incoming
          .where(
            (lot) =>
                current.containsKey(lot.id) &&
                lot.updatedAt.isAfter(current[lot.id]!.updatedAt),
          )
          .length;
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Importer cette sauvegarde ?'),
          content: Text(
            '${incoming.length} lot(s) valide(s).\n$added ajout(s), $updated mise(s) à jour.\n\nLes autres lots restent conservés. À identifiant égal, la modification la plus récente est retenue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Importer'),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
      final ok = await widget.controller.importBackup(text);
      if (!mounted) return;
      if (ok) {
        _input.clear();
        message(
          context,
          'Import terminé : $added ajout(s), $updated mise(s) à jour.',
        );
      } else {
        setState(
          () => _error =
              widget.controller.error ??
              'Une opération est en cours. Réessayez.',
        );
      }
    } on FormatException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Import impossible. Aucun changement effectué.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Sauvegardes')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Icon(Icons.inventory_2_outlined, size: 54),
                const SizedBox(height: 20),
                Text(
                  'Votre réserve vous suit.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Exportez vos lots dans un fichier JSON, puis importez-le sur un autre appareil. Toutes les opérations fonctionnent hors connexion.',
                ),
                const SizedBox(height: 24),
                if (_documents.supportsFiles)
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _export(file: true),
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Enregistrer le fichier JSON'),
                  ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _export,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copier la sauvegarde JSON'),
                ),
                const SizedBox(height: 28),
                Text(
                  'Restaurer ou fusionner',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'La fusion conserve vos lots actuels. Les identifiants évitent les doublons et les dates de modification règlent les conflits. Limite : 2 Mo et 5 000 lots par fichier.',
                ),
                const SizedBox(height: 16),
                if (_documents.supportsFiles)
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _openFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Choisir un fichier JSON'),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _input,
                  enabled: !_busy,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Ou coller une sauvegarde JSON',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _busy ? null : _importText,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Vérifier et importer'),
                ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: LinearProgressIndicator(),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Le JSON contient les noms et notes de vos aliments en clair. Choisissez vous-même où le conserver. Aucune sauvegarde automatique dans le cloud.',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
