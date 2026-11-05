import 'package:flutter/material.dart';
import '../state/pantry_controller.dart';
import 'backup_page.dart';
import 'detail_page.dart';
import 'form_page.dart';
import 'summary_view.dart';
import 'widgets/common.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller});
  final PantryController controller;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _add() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => LotFormPage(controller: widget.controller),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final ready = c.state == LoadState.success || c.state == LoadState.empty;
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Réserve',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 30),
          ),
          actions: [
            IconButton(
              tooltip: 'Sauvegardes',
              onPressed: ready && !c.busy
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BackupPage(controller: c),
                      ),
                    )
                  : null,
              icon: const Icon(Icons.import_export),
            ),
            IconButton(
              tooltip: 'Actualiser',
              onPressed: c.busy ? null : c.load,
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: _body(c),
            ),
          ),
        ),
        floatingActionButton: _tab == 0 && ready
            ? FloatingActionButton.extended(
                onPressed: c.busy ? null : _add,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un aliment'),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (value) => setState(() => _tab = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.kitchen_outlined),
              selectedIcon: Icon(Icons.kitchen),
              label: 'Inventaire',
            ),
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline),
              selectedIcon: Icon(Icons.pie_chart),
              label: 'Bilan',
            ),
          ],
        ),
      );
    },
  );
  Widget _body(PantryController c) {
    if (c.state == LoadState.loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Ouverture du garde-manger…'),
          ],
        ),
      );
    }
    if (c.state == LoadState.error) {
      return SingleChildScrollView(
        child: Notice(
          icon: Icons.cloud_off_outlined,
          title: 'Lecture impossible',
          text: c.error!,
          action: FilledButton.icon(
            onPressed: c.load,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ),
      );
    }
    if (_tab == 1) return SummaryView(controller: c);
    final lots = c.visible;
    return RefreshIndicator(
      onRefresh: c.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          Text(
            'Moins oublier.\nMieux cuisiner.',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${c.stock.length} lot(s) en stock • Vos aliments, au même endroit.',
          ),
          const SizedBox(height: 22),
          if (c.stock.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEADFED),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.restaurant_outlined,
                    size: 32,
                    color: Color(0xFF49334D),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'À cuisiner d’abord',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${c.soonCount} lot(s) à date sous 3 jours. ${c.expiredCount} date(s) dépassée(s).',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          TextField(
            controller: _search,
            onChanged: c.setQuery,
            decoration: InputDecoration(
              hintText: 'Chercher un aliment, un lieu…',
              labelText: 'Rechercher',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: c.query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Effacer la recherche',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        c.setQuery('');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: LotFilter.values
                  .map(
                    (filter) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter.label),
                        selected: c.filter == filter,
                        onSelected: (_) => c.setFilter(filter),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          if (c.busy) const LinearProgressIndicator(),
          if (c.state == LoadState.empty)
            Notice(
              icon: Icons.inventory_2_outlined,
              title: 'Votre réserve commence ici',
              text:
                  'Ajoutez un premier aliment avec sa quantité, son lieu et sa date.',
              action: FilledButton(
                onPressed: _add,
                child: const Text('Ajouter mon premier aliment'),
              ),
            )
          else if (lots.isEmpty)
            Notice(
              icon: Icons.search_off,
              title: 'Aucun aliment pour ce filtre',
              text: 'Essayez un autre mot ou affichez tous les lots.',
              action: TextButton(
                onPressed: () {
                  _search.clear();
                  c.setQuery('');
                  c.setFilter(LotFilter.all);
                },
                child: const Text('Voir tous les lots'),
              ),
            )
          else ...[
            Text(
              '${lots.length} lot(s) • Dates les plus proches en premier',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            ...lots.map(
              (lot) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: Colors.white,
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LotDetailPage(controller: c, id: lot.id),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: placeColor(lot.place).withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            placeIcon(lot.place),
                            color: placeColor(lot.place),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lot.name,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${lot.quantity} ${lot.unit} • ${lot.place.label}',
                              ),
                              const SizedBox(height: 6),
                              ExpiryTag(lot: lot, now: c.clock()),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
