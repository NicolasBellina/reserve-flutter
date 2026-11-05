# Recette Android exécutée — 5 novembre 2026

L'APK release livré a été installé sur **Reserve_API_36**, émulateur au profil Pixel 7, Android **16 / API 36**, ARM64, écran **1080 × 2400**. Le pilotage a utilisé les commandes de test de la CLI Android officielle. Le mode avion était actif, le Wi-Fi et les données mobiles désactivés.

Le fichier APK récupéré depuis l'appareil possède la **même empreinte SHA-256 que l'APK livré** : ce contrôle garantit que la recette porte sur la version de diffusion. Voir [environnement.json](environnement.json). Le tampon de crash Android était vide à la fin des essais.

## Résultats observés

| Étape | Résultat |
|---|---|
| Installation et premier lancement | Installation réussie, démarrage à froid, inventaire vide. |
| Validation | Enregistrer sans nom ni date affiche les erreurs et ne crée aucun lot. |
| Création | Yaourts nature, 4 pièces, Réfrigérateur, date 07/11/2026 : lot visible avec échéance à deux jours. |
| Export natif | Le sélecteur Android crée `Download/reserve-android-recette.json`. Lecture du fichier : format Réserve v1, un lot, quantité et date conformes. |
| Annulations | Retour depuis les sélecteurs d'export et d'import : application utilisable, aucun blocage. |
| Suppression | Annuler conserve la fiche ; confirmer supprime le lot et l'accueil revient à zéro. |
| Restauration | Choisir le fichier par le sélecteur natif annonce un ajout ; confirmation restaure le lot. |
| Idempotence | Reprendre le même fichier annonce zéro ajout et zéro modification ; confirmation sans doublon. |
| JSON invalide | Un fichier contenant `{invalide` est refusé avec un message explicite, sans fusion. |
| Fichier trop grand | Un fichier de 2 097 153 octets est refusé par la lecture native limitée à 2 Mo. |
| Modification | Nom changé en Yaourts nature bio et quantité en 3 ; nouvelles valeurs visibles dans la fiche. |
| Ancienne sauvegarde | Import du fichier initial : zéro mise à jour, le nom modifié et la quantité 3 restent conservés. |
| Recherche et filtres | `yaourt` combiné à Sous 3 jours retrouve le lot ; Date dépassée affiche l'état sans résultat. |
| Indicateur | Passage à Consommé : zéro en stock, un consommé, zéro jeté, taux de 100 %. |
| Arrêt et relance | Arrêt forcé du processus 2394 puis redémarrage à froid dans le processus 3377 : bilan identique, fiche conservant nom, quantité 3 et statut Consommé. |

## Preuves

- [Premier lancement](captures/01-premier-lancement.png), [inventaire](captures/02-inventaire.png) et [fiche](captures/04-fiche-android.png).
- [Sélecteur Android à l'export](captures/03-export-selecteur-android.png), [aperçu de restauration](captures/05-restauration-apercu.png), [import sans doublon](captures/06-import-sans-doublon.png).
- [JSON invalide refusé](captures/07-json-invalide-refuse.png), [bilan après redémarrage](captures/08-bilan-apres-redemarrage.png), [fiche conservée](captures/09-fiche-conservee.png).
- [Fichier réellement exporté](export-verifie.json) et [journal de la session](session.txt).

Les captures proviennent de l'application exécutée, sans montage. Les aliments ont été saisis dans le formulaire de l'émulateur et ne sont pas préchargés dans l'APK. Le journal conserve aussi quelques tentatives de pilotage sur des éléments transitoires ; les résultats ci-dessus correspondent aux états ensuite vérifiés à l'écran ou dans le fichier.

## Portée de cette vérification

Ces essais portent sur Android 16 ARM64 dans un émulateur sur Mac. Aucun téléphone physique ni poste Windows n'a été utilisé. L'APK universel contient aussi x86_64 ; la [notice Windows](../INSTALLATION_WINDOWS.md) permet au correcteur de l'installer dans son émulateur. Les 22 tests automatisés et leurs résultats restent décrits dans [VERIFICATION.md](../VERIFICATION.md).
