# Production Commands (Android)

Ce fichier centralise les commandes a executer pour preparer et builder la version production Android.

## 0) Pre-requis

```bash
flutter --version
dart --version
java -version
```

## 1) Creer le keystore release (une seule fois)

```bash
cd /Users/macbook/Desktop/Developer/Personnel/mbokatour_app_mobile/android
keytool -genkey -v \
  -keystore mbokatour-release-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias mbokatour
```

## 2) Configurer les secrets Android (local uniquement)

Creer `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=mbokatour
storeFile=mbokatour-release-key.jks
```

## 3) Recuperer les empreintes SHA

```bash
cd /Users/macbook/Desktop/Developer/Personnel/mbokatour_app_mobile/android
./gradlew signingReport
```

Copier `SHA1` et `SHA-256` du bloc `Variant: release`.

## 4) Configurer Google OAuth Android

Dans Google Cloud Console:
- Credentials -> OAuth Client ID (Android)
- Package name: `com.mbokatour`
- Ajouter les empreintes `SHA-1` et `SHA-256` de release

## 5) Nettoyer et installer les dependances

```bash
cd /Users/macbook/Desktop/Developer/Personnel/mbokatour_app_mobile
flutter clean
flutter pub get
```

## 6) Verifications avant build

```bash
flutter analyze
```

## 7) Build production

APK:
```bash
flutter build apk --release
```

AAB (Play Store):
```bash
flutter build appbundle --release
```

## 8) Artefacts de sortie

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

## 9) Commandes utiles deja presentes dans le repo

```bash
./generate_keystore.sh
./get_sha1.sh
```

Utiliser ces scripts seulement si leur contenu correspond a vos conventions de securite.
