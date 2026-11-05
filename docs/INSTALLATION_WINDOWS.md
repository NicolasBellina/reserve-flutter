# Lancer Réserve sur Windows — notice pour le correcteur

Le livrable est une **application Android au format APK**. Sous Windows, l'installation se fait dans un téléphone virtuel Android. Il suffit du fichier APK : aucune compilation du projet ni installation de Flutter n'est nécessaire.

## 1. Télécharger la livraison

Depuis la [release v1.0.0](https://github.com/NicolasBellina/reserve-flutter/releases/tag/v1.0.0), télécharger **reserve-1.0.0.apk**. Le fichier est signé avec la clé de diffusion propre à Réserve et contient les architectures ARM 32 bits, ARM64 et **x86_64**.

Version : 1.0.0 (code 1). Identifiant : `fr.nicolasbellina.reserve`. Android minimal : 7.0 / API 24. La recette a été effectuée sous Android 16 / API 36 ARM64 sur Mac. L'émulateur Windows lui-même n'a pas été testé sur cette machine.

## 2. Préparer un téléphone virtuel

1. Installer [Android Studio pour Windows](https://developer.android.com/studio/install) si aucun émulateur Android n'est déjà disponible.
2. Ouvrir **Device Manager** et créer un téléphone virtuel, par exemple un Pixel.
3. Choisir une image Android compatible avec le PC, API 24 ou supérieure. Une image API 36 reproduit la version Android de la recette. Sur un PC Intel/AMD, choisir **x86_64**.
4. Télécharger l'image si nécessaire, terminer la création, puis démarrer le téléphone virtuel.

L'installation des outils et de l'image nécessite Internet. Réserve n'en a pas besoin une fois installée. En cas d'échec au démarrage de l'émulateur, consulter la [configuration officielle de l'accélération matérielle](https://developer.android.com/studio/run/emulator-acceleration).

## 3. Installer l'APK

Glisser **reserve-1.0.0.apk** depuis l'Explorateur Windows sur l'écran du téléphone virtuel. Attendre la fin de l'installation, puis ouvrir **Réserve** depuis les applications Android. Cette méthode est décrite dans la [documentation officielle de l'émulateur](https://developer.android.com/studio/run/emulator-install-add-files).

Si le glisser-déposer est indisponible, utiliser PowerShell avec les Platform Tools du SDK. Dans le dossier du téléchargement :

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r .\reserve-1.0.0.apk
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell am start -n fr.nicolasbellina.reserve/.MainActivity
```

Adapter le chemin si le SDK Android a été installé ailleurs. Avec plusieurs appareils connectés, ajouter `-s <identifiant>` avant `install` et `shell`, en reprenant l'identifiant affiché par `devices`.

## 4. Parcours de correction rapide

1. L'inventaire initial est vide. Ajouter un aliment : vérifier le refus sans nom ni date, puis enregistrer une saisie valide.
2. Ouvrir sa fiche, modifier sa quantité, retrouver la modification ; utiliser recherche et filtre.
3. Marquer un lot comme consommé et consulter le bilan recalculé.
4. Ouvrir Sauvegardes, enregistrer un JSON dans **Downloads/Téléchargements**, puis le sélectionner pour l'import. Réimporter le même fichier : zéro doublon.
5. Supprimer un lot après confirmation ; fermer complètement Réserve, la rouvrir et vérifier les données restantes.

La [recette complète](RECETTE.md) précise les résultats attendus et le scénario d'échec. Les [preuves Android](android/RECETTE_EXECUTEE.md) montrent les résultats obtenus sur l'APK livré.

## Intégrité du téléchargement

Le fichier **SHA256SUMS**, fourni dans la release, donne l'empreinte de l'APK. La comparer avec celle affichée par :

```powershell
(Get-FileHash .\reserve-1.0.0.apk -Algorithm SHA256).Hash
```

Une installation de mise à jour doit utiliser la même signature. Une éventuelle désinstallation efface la base locale : exporter les données avant de désinstaller une version déjà utilisée.
