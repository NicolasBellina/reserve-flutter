import 'package:flutter/material.dart';
import '../models/food_lot.dart';
import '../state/pantry_controller.dart';
import 'widgets/common.dart';

class LotFormPage extends StatefulWidget {
  const LotFormPage({super.key, required this.controller, this.lot});
  final PantryController controller;
  final FoodLot? lot;
  @override
  State<LotFormPage> createState() => _LotFormPageState();
}

class _LotFormPageState extends State<LotFormPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _quantity, _notes;
  late StoragePlace _place;
  late LotStatus _status;
  late String _unit;
  DateTime? _expiry;
  bool _saving = false, _submitted = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final lot = widget.lot;
    _name = TextEditingController(text: lot?.name);
    _quantity = TextEditingController(text: lot?.quantity.toString() ?? '1');
    _notes = TextEditingController(text: lot?.notes);
    _place = lot?.place ?? StoragePlace.fridge;
    _status = lot?.status ?? LotStatus.available;
    _unit = lot?.unit ?? units.first;
    _expiry = lot?.expiry;
  }

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = widget.controller.clock();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry ?? DateTime(now.year, now.month, now.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Date indiquée sur l’emballage',
    );
    if (picked != null && mounted) setState(() => _expiry = picked);
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (!_form.currentState!.validate() || _expiry == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    final now = widget.controller.clock();
    final old = widget.lot;
    final lot = FoodLot(
      id: old?.id ?? newId(),
      name: _name.text.trim(),
      quantity: int.parse(_quantity.text.trim()),
      unit: _unit,
      place: _place,
      status: _status,
      expiry: _expiry!,
      createdAt: old?.createdAt ?? now,
      updatedAt: old != null && now.isBefore(old.updatedAt)
          ? old.updatedAt
          : now,
      notes: _notes.text.trim(),
    );
    final ok = await widget.controller.save(lot);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      message(context, old == null ? 'Aliment ajouté.' : 'Aliment modifié.');
      Navigator.pop(context);
    } else {
      setState(
        () => _error =
            widget.controller.error ?? 'Une opération est en cours. Réessayez.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lot == null ? 'Ajouter un aliment' : 'Modifier l’aliment',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  Text(
                    'Un lot, une date, un endroit.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Séparez les lots si leurs dates sont différentes. Les champs marqués * sont obligatoires.',
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _name,
                    enabled: !_saving,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Aliment *',
                      hintText: 'Ex. Yaourts nature',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Saisissez le nom de l’aliment.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _quantity,
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Quantité *'),
                    validator: (v) {
                      final quantity = int.tryParse(v?.trim() ?? '');
                      return quantity == null ||
                              quantity < 1 ||
                              quantity > 999999
                          ? 'Saisissez un entier entre 1 et 999 999.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: _unit,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Unité'),
                    items: units
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _unit = v!),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<StoragePlace>(
                    initialValue: _place,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Emplacement'),
                    items: StoragePlace.values
                        .map(
                          (p) =>
                              DropdownMenuItem(value: p, child: Text(p.label)),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _place = v!),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Text(
                        _expiry == null
                            ? 'Choisir la date *'
                            : 'Date : ${displayDate(_expiry!)}',
                      ),
                    ),
                  ),
                  if (_submitted && _expiry == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Choisissez la date indiquée sur l’emballage.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cette date est un repère de rangement. Vérifiez les indications et les conditions de conservation de l’emballage.',
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<LotStatus>(
                    initialValue: _status,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Statut'),
                    items: LotStatus.values
                        .map(
                          (s) =>
                              DropdownMenuItem(value: s, child: Text(s.label)),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _status = v!),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _notes,
                    enabled: !_saving,
                    maxLines: 3,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Ex. Ouvert lundi, à utiliser dans une sauce',
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
