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
flutter build appbundle --release \
  --dart-define=BASE_URL=https://mbokatour.com/api \
  --dart-define=API_KEY=YOUR_API_KEY \
  --dart-define=GOOGLE_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_GOOGLE_SERVER_CLIENT_ID
```

APK (debug distribution locale uniquement):
```bash
flutter build apk --release \
  --dart-define=BASE_URL=https://mbokatour.com/api \
  --dart-define=API_KEY=YOUR_API_KEY \
  --dart-define=GOOGLE_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_GOOGLE_SERVER_CLIENT_ID
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
keytool -list -v -keystore mbokatour-upload-key.jks

Entrez le mot de passe du fichier de clés :  
Type de fichier de clés : PKCS12
Fournisseur de fichier de clés : SUN

Votre fichier de clés d'accès contient 1 entrée

Nom d'alias : mbokatour
Date de création : 4 mars 2026
Type d'entrée : PrivateKeyEntry
Longueur de chaîne du certificat : 1
Certificat[1]:
Propriétaire : CN=Cedric Mungobo, OU=AXIO Digital, O=AXIO Digital, L=Kinshasa, ST=Kinshasa, C=cd
Emetteur : CN=Cedric Mungobo, OU=AXIO Digital, O=AXIO Digital, L=Kinshasa, ST=Kinshasa, C=cd
Numéro de série : 4a2ad96ec2f51332
Valide du Wed Mar 04 00:07:32 WAT 2026 au Sun Jul 20 00:07:32 WAT 2053
Empreintes du certificat :
         SHA 1: F2:AB:91:BE:FE:D7:E1:06:12:00:8F:C2:A9:31:19:22:C8:61:11:8C
         SHA 256: 77:65:C6:7E:1B:4C:49:7F:35:9D:72:1A:4F:BA:0E:86:18:D4:3B:63:54:36:9F:6E:3C:BD:53:2F:20:D2:1D:CF
Nom de l'algorithme de signature : SHA256withRSA
Algorithme de clé publique du sujet : Clé RSA 2048 bits
Version : 3

Extensions : 

#1: ObjectId: 2.5.29.14 Criticality=false
SubjectKeyIdentifier [
KeyIdentifier [
0000: 43 26 FF 02 62 6D 78 2D   AC FB 9E F6 CA C6 BA 53  C&..bmx-.......S
0010: BF E8 E1 D9                                        ....
]
]
