# Installer et reconstruire Réserve

## APK fourni

Fichier : `livraison/reserve-1.0.0.apk`. Version 1.0.0 (code 1), identifiant `fr.nicolasbellina.reserve`, Android 7.0 / API 24 minimum. APK universel ARM 32 bits, ARM64 et x86_64. La signature v2 a été vérifiée par apksigner ; le certificat est propre au projet et n'est pas celui du debug. L'empreinte du fichier est dans `livraison/SHA256SUMS`.

Transférer l'APK sur le téléphone, l'ouvrir, autoriser ponctuellement l'installation depuis l'application qui ouvre le fichier si Android le demande, puis lancer Réserve. Avec un téléphone de développement connecté :

```sh
adb install -r livraison/reserve-1.0.0.apk
```

L'installation effective et le sélecteur de fichiers natif restent à vérifier sur appareil. Ne pas présenter la compilation comme une preuve d'exécution sur téléphone. Un APK ne s'installe pas sur iPhone.

## Reconstruire sur ce Mac

```sh
./tool/flutterw pub get
./tool/flutterw analyze
./tool/flutterw test
./tool/build_apk
```

Le script utilise, s'ils existent, le SDK Android et le cache Gradle de `../.tools`, ainsi que le Java d'Android Studio. Sur une autre machine, installer Flutter 3.47+ et Android Studio/SDK, configurer les licences avec les outils officiels, puis fournir sa propre signature.

La clé générée pour cette livraison se trouve dans `.private/reserve-release.p12`. Les paramètres dans `android/key.properties` sont privés, exclus du dépôt et lisibles seulement par le propriétaire sur ce Mac. **Sauvegarder ces deux fichiers séparément** pour pouvoir signer les mises à jour. Ne pas les transmettre au professeur, les publier ou les ajouter à Git.

## Autre machine : nouvelle clé personnelle

```sh
mkdir -p .private
keytool -genkeypair -v -keystore .private/reserve-release.p12 -storetype PKCS12 -alias reserve -keyalg RSA -keysize 3072 -validity 10000
```

L'outil demande les informations et le mot de passe sans les placer dans le code source. Créer localement `android/key.properties` :

```properties
storeFile=../.private/reserve-release.p12
storePassword=<mot-de-passe-local>
keyAlias=reserve
keyPassword=<mot-de-passe-local>
```

Ces valeurs sont des emplacements à compléter, pas des identifiants fournis. Une clé différente ne permet pas de mettre à jour l'APK déjà installé ; il faudrait désinstaller l'ancien APK, ce qui efface sa base. Exporter ses données avant toute désinstallation.

## Rendu

Transmettre le dépôt source, l'APK en pièce jointe et les documents/captures de docs. Les caches, le SDK et build ne font pas partie du rendu. L'APK est volontairement ignoré par Git et présent dans le dossier local ; l'ajouter séparément à une release si un dépôt distant est créé. Aucun dépôt distant n'a été créé ou publié dans cette tâche.
