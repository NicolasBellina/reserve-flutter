# Présentation sur téléphone — environ 5 minutes

Ce support prépare la présentation autorisée par le sujet en alternative à une vidéo. Aucune vidéo de démonstration n'est annoncée comme livrée.

**0:00 — Besoin.** « Je cuisine pour moi et j'oublie certains achats. Réserve rassemble les lots et leurs dates sans compte ni réseau. L'utilisateur cible est un étudiant ou un petit foyer. » Montrer l'inventaire et expliquer qu'un lot représente une quantité ayant la même date et le même lieu.

**0:40 — Parcours.** En mode avion, ouvrir le formulaire, montrer une validation refusée, ajouter des yaourts, consulter et modifier la fiche. Montrer recherche et filtre. Ajouter un deuxième lot, supprimer après confirmation. Fermer et rouvrir l'application pour prouver la persistance.

**2:20 — Bilan.** Marquer un lot comme consommé et ouvrir Bilan. Expliquer que le pourcentage porte sur les lots consommés et jetés, pas sur les grammes ; les filtres n'affectent pas la synthèse.

**2:50 — Différenciation.** Enregistrer un JSON avec le sélecteur Android, le réimporter, montrer l'aperçu et l'absence de doublon. Saisir un JSON invalide pour déclencher une erreur contrôlée et vérifier que les données restent présentes.

**3:40 — Architecture.** Montrer le dossier lib : widgets → ChangeNotifier → repository → SQLite. Aucune requête SQL dans une page. Le codec valide les fichiers ; un canal Kotlin ouvre les documents choisis, sans permission générale. Expliquer création/modification, ID stable et transaction d'import.

**4:20 — Qualité et difficulté.** Montrer les sorties analyse et tests. Difficulté principale : garantir une fusion fiable après import répété ou fichier partiellement invalide. Solution : valider tout le fichier avant l'import, conserver les identifiants, comparer les modifications et écrire dans une transaction. Un test provoque une erreur sur la deuxième insertion et prouve que la première est annulée.

**4:50 — Limites.** Pas de synchronisation automatique ; l'horloge des appareils doit être correcte ; les sauvegardes sont en clair et les suppressions ne sont pas propagées. Conclusion orale personnelle : citer une amélioration utile, par exemple un historique de consommation par mois.
