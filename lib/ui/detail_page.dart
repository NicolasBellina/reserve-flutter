import 'package:flutter/material.dart';
import '../models/food_lot.dart';
import '../state/pantry_controller.dart';
import 'form_page.dart';
import 'widgets/common.dart';

class LotDetailPage extends StatelessWidget {
  const LotDetailPage({super.key, required this.controller, required this.id});
  final PantryController controller;
  final String id;
  Future<void> _delete(BuildContext context, FoodLot lot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cet aliment ?'),
        content: Text(
          'Le lot « ${lot.name} » sera définitivement supprimé. Pour le conserver dans le bilan, marquez-le comme consommé ou jeté.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final ok = await controller.delete(lot.id);
    if (!context.mounted) return;
    if (ok) {
      message(context, 'Aliment supprimé.');
      Navigator.pop(context);
    } else {
      message(context, controller.error ?? 'Opération en cours. Réessayez.');
    }
  }

  Future<void> _consume(BuildContext context, FoodLot lot) async {
    final now = controller.clock();
    final ok = await controller.save(
      lot.withStatus(
        LotStatus.consumed,
        now.isBefore(lot.updatedAt) ? lot.updatedAt : now,
      ),
    );
    if (context.mounted) {
      message(
        context,
        ok
            ? 'Lot marqué comme consommé. Le bilan est à jour.'
            : controller.error ?? 'Réessayez.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final matches = controller.lots.where((lot) => lot.id == id);
      final lot = matches.isEmpty ? null : matches.first;
      return Scaffold(
        appBar: AppBar(title: const Text('Fiche aliment')),
        body: lot == null
            ? const Notice(
                icon: Icons.inventory_2_outlined,
                title: 'Lot supprimé',
                text: 'Revenez à votre inventaire.',
              )
            : SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: placeColor(
                                lot.place,
                              ).withValues(alpha: .10),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(
                              placeIcon(lot.place),
                              size: 54,
                              color: placeColor(lot.place),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          lot.name,
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        ExpiryTag(lot: lot, now: controller.clock()),
                        const SizedBox(height: 24),
                        _line(
                          context,
                          'Quantité',
                          '${lot.quantity} ${lot.unit}',
                        ),
                        _line(context, 'Emplacement', lot.place.label),
                        _line(
                          context,
                          'Date sur l’emballage',
                          displayDate(lot.expiry),
                        ),
                        _line(context, 'Statut', lot.status.label),
                        if (lot.notes.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Notes',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          SelectableText(lot.notes),
                        ],
                        const SizedBox(height: 28),
                        if (lot.status == LotStatus.available)
                          FilledButton.icon(
                            onPressed: controller.busy
                                ? null
                                : () => _consume(context, lot),
                            icon: const Icon(Icons.restaurant),
                            label: const Text('Marquer comme consommé'),
                          ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: controller.busy
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => LotFormPage(
                                      controller: controller,
                                      lot: lot,
                                    ),
                                  ),
                                ),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Modifier'),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: controller.busy
                              ? null
                              : () => _delete(context, lot),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Supprimer'),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Ajouté le ${displayDate(lot.createdAt.toLocal())}\nModifié le ${displayDate(lot.updatedAt.toLocal())}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (controller.busy) const LinearProgressIndicator(),
                      ],
                    ),
                  ),
                ),
              ),
      );
    },
  );
  Widget _line(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        const Divider(),
      ],
    ),
  );
}
