# Vérification du 5 novembre 2026

## Exécuté et réussi

| Contrôle | Résultat | Preuve |
|---|---|---|
| Flutter stable / Dart | 3.47.9 / 3.13.7 | Environnement du build |
| `flutter analyze` | Aucun problème | [Sortie brute](flutter-analyze.txt) |
| `flutter test --reporter expanded` | 22 réussites, 0 échec | [Sortie brute](flutter-test.txt) |
| Build Android release | Réussi, APK universel de 57 958 434 octets | [Journal](build-apk.txt) |
| Signature APK | v2 valide, RSA 3072, certificat Réserve | [apksigner](apk-signature.txt) |
| Alignement ZIP et ELF | ZIP valide et 9 bibliothèques alignées sur 16 Ko | [Contrôle](apk-alignement.txt) |
| Build Web autonome | Réussi | [Journal](build-web.txt) |
| Exécution Web sur localhost | Réussie, viewport 390 × 844 | [Captures](captures/) |

Les journaux de tests contiennent volontairement des erreurs simulées `StateError` : ce sont les scénarios de récupération, suivis d'assertions réussies. Le build Web émet un avertissement sur la police Cupertino non embarquée ; l'interface utilise les icônes Material, visibles dans les captures. Ce n'est pas une erreur d'analyse.

## Répartition des 22 tests

- 4 modèle : sérialisation, échéances par jour, valeurs invalides et génération d'identifiants.
- 3 codec JSON : aller-retour avec accents, refus des formats/doublons/versions et taille UTF-8.
- 6 contrôleur : états, recherche et filtre, bilan global, échecs d'écriture, fusion, import invalide et destruction pendant une opération.
- 3 SQLite sur disque : CRUD après réouverture, rollback d'une transaction partiellement exécutée et résolution de conflits par date.
- 6 widgets : CRUD validé avec modification et suppression confirmée, échec d'écriture récupérable, lecture en erreur puis nouvelle tentative, chargement visible, import invalide et écran 360 px avec texte à 150 %.

## Vérification manuelle réellement effectuée dans le navigateur

1. Premier lancement : inventaire vide, zéro lot, action d'ajout visible.
2. Formulaire sans nom ni date : validation refusée.
3. Création de Yaourts nature, 4 pièces au réfrigérateur, date 07/11/2026 et note de recette ; retour à l'inventaire avec succès.
4. Consultation puis modification du nom en Yaourts nature bio ; résultat visible dans la fiche et la liste.
5. Recherche et filtre Sous 3 jours : lot retrouvé.
6. Export JSON par copie : format `reserve` et un lot vérifiés.
7. JSON invalide : message visible, inventaire conservé.
8. Import du JSON exporté : aperçu de 1 lot valide, zéro ajout et zéro mise à jour ; confirmation sans doublon.
9. Rechargement complet de la page : le lot modifié est toujours présent, lu depuis SQLite/IndexedDB.
10. Passage du lot à Consommé : bilan recalculé à zéro lot en stock, un consommé, zéro jeté et 100 % des lots terminés consommés.

Ces données ont été saisies dans le navigateur de vérification. Elles ne font pas partie de la base initiale distribuée. Les images du dossier captures sont des captures de cette application exécutée, sans montage ni remplacement des valeurs.

## À réaliser sur Android avant soutenance

Aucun appareil ou émulateur Android n'était disponible pour la recette. La compilation, l'activité Kotlin et la signature sont vérifiées ; **l'installation effective, le fonctionnement du sélecteur natif et la persistance après arrêt sur téléphone ne sont pas revendiqués comme testés**. La persistance SQLite sur disque est couverte automatiquement et la persistance Web a été constatée manuellement.

Suivre [RECETTE.md](RECETTE.md) sur téléphone ou émulateur, en mode avion. Les actions de suppression ont été vérifiées dans les tests de widgets avec confirmation et annulation. La copie JSON, l'import, les dates, la recherche et le bilan ne dépendent pas du sélecteur Android.

## Difficultés résolues

- Une archive native de sqlite3 3.5.2 ne correspondait pas à son empreinte attendue lors du build Android. La vérification d'intégrité n'a pas été désactivée : la dépendance a été mise à jour, avec version exacte enregistrée dans pubspec.lock, et le build final a réussi.
- Le template Flutter désactivait Kotlin intégré alors que l'application contient un canal natif en Kotlin. La configuration a été corrigée selon la procédure Flutter 3.47 : Kotlin intégré activé dans Gradle ; activité effectivement compilée et APK construit sans ignorer le contrôle Android Lint.
- Les premières interactions des tests défilaient dans un champ de texte plutôt que dans la liste du formulaire. Le scénario cible maintenant la zone verticale du formulaire. Les tests ont ensuite vérifié le parcours complet sur petit écran.

## Intégrité et confidentialité

L'empreinte du fichier final est dans [SHA256SUMS](../livraison/SHA256SUMS). La clé privée, les paramètres de signature, les bases, le build et les caches sont exclus du dépôt Git. Le certificat public de signature est documenté ; aucun mot de passe n'apparaît dans les preuves.
