# Production Commands (Android)

Ce fichier centralise les etapes pour preparer et publier une version Android (workflow Flutter officiel).

Source officielle Flutter:
- https://docs.flutter.dev/deployment/android

## 0) Pre-requis

```bash
flutter --version
dart --version
java -version
```

Compte Google Play Developer requis pour la publication.

## 1) Mettre a jour la version applicative

Dans `pubspec.yaml`, incrementer:
- `versionName` via `version: x.y.z+N` (partie `x.y.z`)
- `versionCode` via `N` (partie apres `+`)

Exemple:
```yaml
version: 1.3.0+12
```

## 2) Creer la cle de signature upload (une seule fois)

```bash
cd /Users/macbook/Desktop/Developer/Personnel/mbokatour_app_mobile/android
keytool -genkey -v \
  -keystore mbokatour-upload-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias mbokatour
```

Conserver ce fichier en lieu sur. Ne jamais le perdre.

## 3) Configurer `android/key.properties` (local, non versionne)

Creer `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=mbokatour
storeFile=mbokatour-upload-key.jks
```

Le projet charge deja ce fichier dans `android/app/build.gradle.kts`.

## 4) Recuperer SHA-1 / SHA-256 de release

```bash
cd /Users/macbook/Desktop/Developer/Personnel/mbokatour_app_mobile/android
./gradlew signingReport
```

Copier `SHA1` et `SHA-256` du bloc `Variant: release`.

## 5) Configurer Google OAuth Android

Dans Google Cloud Console:
- `Credentials` -> `Create Credentials` -> `OAuth client ID` -> `Android`
- Package name: `com.mbokatour`
- Ajouter les empreintes `SHA-1` et `SHA-256` release

## 6) Verifications avant release

```bash
cd /Users/macbook/Desktop/Developer/Personnel/mbokatour_app_mobile
flutter clean
flutter pub get
flutter analyze
flutter test
./scripts/release_check.sh
```

## 7) Build de production (AAB recommande pour Play Store)

AAB:
```bash
flutter build appbundle --release --dart-define-from-file=.env
```

APK (debug distribution locale uniquement):
```bash
flutter build apk --release --dart-define-from-file=.env
```

Run local (debug) avec les memes variables:
```bash
flutter run --dart-define-from-file=.env
```

## 8) Artefacts de sortie

- AAB: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/flutter-apk/app-release.apk`

## 9) Publication Google Play Console

1. Ouvrir Play Console -> votre app -> `Testing` (Internal/Closed) ou `Production`.
2. Creer une release.
3. Uploader `app-release.aab`.
4. Completer release notes, pays, contenus, questionnaires obligatoires.
5. Soumettre pour review, puis publier.

## 10) Scripts utiles presents dans le repo

```bash
./generate_keystore.sh
./get_sha1.sh
```

Verifier le contenu de ces scripts avant usage en equipe.
