# Recette manuelle — Réserve

À exécuter sur téléphone ou émulateur Android avant la soutenance. **Cette liste est une procédure attendue, pas une attestation d'exécution Android.** Les contrôles réellement effectués sont consignés dans VERIFICATION.md.

## Préparation

Installer `livraison/reserve-1.0.0.apk`, ouvrir Réserve et activer le mode avion. Le premier lancement doit afficher 0 lot et « Votre réserve commence ici ». Ne pas désinstaller entre les étapes de persistance : Android efface alors la base.

## Parcours principal

1. Ajouter un aliment. Enregistrer sans nom ni date : messages explicites, aucune ligne créée.
2. Saisir « Yaourts nature », quantité 0 : validation refusée. Corriger à 4 pièces, emplacement Réfrigérateur, choisir une date dans deux jours, noter « Lot de recette ». Enregistrer : retour à l'inventaire et message de réussite.
3. Retrouver le lot, ouvrir sa fiche et vérifier nom, quantité, emplacement et date. Modifier son nom en « Yaourts nature bio » et la quantité à 3. Vérifier la fiche puis la liste.
4. Rechercher `yaourt`, sélectionner Sous 3 jours : le lot est visible. Choisir Date dépassée : il disparaît et l'état « Aucun aliment pour ce filtre » apparaît. Effacer la recherche et revenir à En stock.
5. Ajouter un deuxième lot « Riz », 500 g, Placard, date dans un mois. Bilan : deux lots en stock, un au réfrigérateur et un au placard. Vérifier que filtrer la liste ne change pas ces totaux.
6. Sur la fiche des yaourts, marquer comme consommé. Le filtre En stock affiche seulement le riz ; Consommés retrouve les yaourts. Le bilan affiche 1 en stock, 1 consommé, 0 jeté, 100 % des lots terminés consommés.
7. Supprimer le riz : Annuler conserve le lot ; confirmer Supprimer le retire. Le bilan doit afficher 0 en stock et 1 consommé.
8. Fermer complètement l'application (la retirer des applications récentes, ou forcer son arrêt), puis la relancer. Le riz doit rester absent et les yaourts consommés rester présents via Consommés ou Tous. Le bilan garde son résultat.

## Fichiers et fusion JSON — fonctionnalité distinctive

1. Ouvrir Sauvegardes, Enregistrer le fichier JSON, choisir Téléchargements. Le fichier est créé et l'application confirme. Annuler une seconde exportation : retour sans blocage ni modification.
2. Choisir un fichier JSON et reprendre le fichier exporté. Avant import : zéro ajout et zéro mise à jour. Confirmer deux fois sur le même fichier : aucun doublon.
3. Modifier localement les yaourts, puis réimporter l'ancienne sauvegarde : elle ne doit pas écraser la modification récente.
4. Pour montrer un ajout restauré, créer un lot temporaire « Pommes », exporter, supprimer ce lot après confirmation, réimporter le fichier : aperçu d'un ajout, puis retour de Pommes avec le même identifiant.
5. Annuler le sélecteur d'import : retour normal. Annuler la confirmation de fusion : rien n'est modifié.
6. Le fournisseur local Téléchargements doit fonctionner en mode avion. Un emplacement Drive proposé par Android dépend de son fournisseur et du réseau ; ce n'est pas une synchronisation Réserve.

## Échec contrôlé et diagnostic

1. Copier l'export valide et noter le nombre de lots.
2. Dans « Ou coller une sauvegarde JSON », saisir `{invalide`, puis Vérifier et importer.
3. Attendu : message « Sauvegarde invalide », aucun dialogue de confirmation, aucune modification des compteurs ni de la base après relance.
4. Réessayer avec le JSON valide : aperçu puis import réussi. Cela montre la récupération après erreur.
5. Variantes : version 999, quantité négative, deux lots portant le même id, date `2026-02-31`, fichier > 2 Mo. Tous doivent être refusés avant toute écriture.

L'échec SQL est simulé automatiquement avec un trigger `RAISE(ABORT)` pendant le deuxième lot d'un import : même le premier lot est annulé. Les tests de widgets injectent aussi une erreur d'écriture, vérifient le message et la conservation de la saisie, puis réussissent une nouvelle tentative. Il n'existe pas de bouton de panne artificiel dans l'application livrée.

## Lisibilité

Tester largeur 360 px, orientation paysage, clavier ouvert, grandes tailles de texte et nom de 80 caractères. Les formulaires doivent défiler, les champs rester accessibles et les filtres pouvoir défiler horizontalement. Revenir du mode veille après changement de jour : les échéances se recalculent.
