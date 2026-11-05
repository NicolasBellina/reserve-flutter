import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reserve/main.dart';
import 'fake_repository.dart';

Future<void> tap(WidgetTester tester, Finder target) async {
  if (find.byType(SnackBar).evaluate().isNotEmpty) {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      220,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> fill(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Aliment *'),
    'Lentilles',
  );
  await tap(tester, find.text('Choisir la date *'));
  await tap(tester, find.text('OK'));
}

void main() {
  testWidgets(
    'formulaire validé, création, modification et suppression confirmée',
    (tester) async {
      final repo = FakeRepository();
      await tester.pumpWidget(ReserveApp(repository: repo));
      await tester.pumpAndSettle();
      expect(find.text('Votre réserve commence ici'), findsOneWidget);
      await tap(tester, find.text('Ajouter mon premier aliment'));
      await tap(tester, find.text('Enregistrer'));
      expect(repo.items, isEmpty);
      await tester.drag(find.byType(ListView), const Offset(0, 1200));
      await tester.pumpAndSettle();
      expect(find.text('Saisissez le nom de l’aliment.'), findsOneWidget);
      await fill(tester);
      await tap(tester, find.text('Enregistrer'));
      expect(repo.items.single.name, 'Lentilles');
      await tap(tester, find.text('Lentilles'));
      await tap(tester, find.text('Modifier'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Aliment *'),
        'Lentilles vertes',
      );
      await tap(tester, find.text('Enregistrer'));
      expect(repo.items.single.name, 'Lentilles vertes');
      await tap(tester, find.text('Supprimer'));
      await tap(tester, find.text('Annuler'));
      expect(repo.items, hasLength(1));
      await tap(tester, find.text('Supprimer'));
      await tap(tester, find.widgetWithText(FilledButton, 'Supprimer'));
      expect(repo.items, isEmpty);
      expect(find.text('Votre réserve commence ici'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'échec écriture conserve le formulaire et permet une nouvelle tentative',
    (tester) async {
      final repo = FakeRepository()..failWrite = true;
      await tester.pumpWidget(ReserveApp(repository: repo));
      await tester.pumpAndSettle();
      await tap(tester, find.text('Ajouter mon premier aliment'));
      await fill(tester);
      await tap(tester, find.text('Enregistrer'));
      expect(repo.items, isEmpty);
      expect(find.textContaining('Enregistrement impossible'), findsOneWidget);
      repo.failWrite = false;
      await tap(tester, find.text('Enregistrer'));
      expect(repo.items.single.name, 'Lentilles');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('erreur de lecture visible puis réessayer', (tester) async {
    final repo = FakeRepository()..failRead = true;
    await tester.pumpWidget(ReserveApp(repository: repo));
    await tester.pumpAndSettle();
    expect(find.text('Lecture impossible'), findsOneWidget);
    repo.failRead = false;
    await tap(tester, find.text('Réessayer'));
    expect(find.text('Votre réserve commence ici'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('chargement réellement visible', (tester) async {
    final repo = FakeRepository()..blocker = Completer<void>();
    await tester.pumpWidget(ReserveApp(repository: repo));
    await tester.pump();
    expect(find.text('Ouverture du garde-manger…'), findsOneWidget);
    repo.blocker!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Votre réserve commence ici'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('JSON invalide refusé sans changement', (tester) async {
    final repo = FakeRepository([example()]);
    await tester.pumpWidget(ReserveApp(repository: repo));
    await tester.pumpAndSettle();
    await tap(tester, find.byTooltip('Sauvegardes'));
    await tester.scrollUntilVisible(
      find.byType(TextField),
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.enterText(find.byType(TextField), '{invalide');
    await tap(tester, find.text('Vérifier et importer'));
    expect(find.textContaining('Sauvegarde invalide'), findsOneWidget);
    expect(repo.items, hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('petit écran et texte agrandi restent défilants', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(ReserveApp(repository: FakeRepository()));
    await tester.pumpAndSettle();
    await tap(tester, find.text('Ajouter mon premier aliment'));
    await tap(tester, find.text('Enregistrer'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
