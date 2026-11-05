import 'package:flutter/material.dart';
import '../models/food_lot.dart';
import '../state/pantry_controller.dart';

class SummaryView extends StatelessWidget {
  const SummaryView({super.key, required this.controller});
  final PantryController controller;
  @override
  Widget build(BuildContext context) {
    final c = controller;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Chaque lot compte.',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const Text(
          'Votre bilan est calculé sur tous les lots enregistrés, quels que soient la recherche et le filtre.',
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFEADFED),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${c.stock.length}',
                style: Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Text('lot(s) encore en stock'),
              const SizedBox(height: 18),
              Text(
                '${c.soonCount} à date sous 3 jours\n${c.expiredCount} avec une date dépassée',
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Où sont vos aliments ?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...StoragePlace.values.map((place) {
          final count = c.stock.where((lot) => lot.place == place).length;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${place.label} : $count lot(s)'),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: c.stock.isEmpty ? 0 : count / c.stock.length,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 24),
        Text(
          'Ce qui a été utilisé',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Text('${c.consumedCount} consommé(s) • ${c.discardedCount} jeté(s)'),
        const SizedBox(height: 12),
        if (c.consumedCount + c.discardedCount == 0)
          const Text(
            'Marquez un lot comme consommé ou jeté pour commencer le bilan.',
          )
        else
          Text(
            '${(c.usedRatio * 100).round()} % des lots terminés ont été consommés.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        const SizedBox(height: 16),
        const Text(
          'Un lot de riz et un lot de yaourts comptent chacun pour un lot. Ce bilan ne mesure ni le poids ni la valeur des aliments. Les lots supprimés sont retirés du calcul.',
        ),
        const SizedBox(height: 28),
        const Text(
          'La réserve reste sur cet appareil. Pensez à exporter une sauvegarde avant de changer de téléphone.',
        ),
      ],
    );
  }
}
