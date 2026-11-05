import 'package:flutter/material.dart';
import '../../models/food_lot.dart';

IconData placeIcon(StoragePlace place) => switch (place) {
  StoragePlace.fridge => Icons.kitchen_outlined,
  StoragePlace.freezer => Icons.ac_unit,
  StoragePlace.cupboard => Icons.shelves,
};
Color placeColor(StoragePlace place) => switch (place) {
  StoragePlace.fridge => const Color(0xFF315F78),
  StoragePlace.freezer => const Color(0xFF4C5190),
  StoragePlace.cupboard => const Color(0xFF71552E),
};
void message(BuildContext context, String text) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class Notice extends StatelessWidget {
  const Notice({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    this.action,
  });
  final IconData icon;
  final String title, text;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Text(text, textAlign: TextAlign.center),
        if (action != null)
          Padding(padding: const EdgeInsets.only(top: 24), child: action!),
      ],
    ),
  );
}

class ExpiryTag extends StatelessWidget {
  const ExpiryTag({super.key, required this.lot, required this.now});
  final FoodLot lot;
  final DateTime now;
  @override
  Widget build(BuildContext context) {
    final available = lot.status == LotStatus.available;
    final urgent = available && lot.daysLeft(now) <= 3;
    return Text(
      available ? lot.expiryLabel(now) : lot.status.label,
      style: TextStyle(
        color: urgent
            ? const Color(0xFF805300)
            : Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
