# Production Commands (iOS)

Ce fichier centralise les etapes et commandes pour preparer et publier la version iOS en production.

## 0) Pre-requis

```bash
flutter --version
dart --version
xcodebuild -version
pod --version
```

Compte Apple Developer actif requis.

## 1) Ouvrir le projet iOS dans Xcode

```bash
cd /Users/macbook/Desktop/Developer/Personnel/mbokatour_app_mobile
open ios/Runner.xcworkspace
```

Dans Xcode (`Runner` target):
- `Signing & Capabilities`
- Selectionner la bonne `Team`
- Verifier `Bundle Identifier`
- Activer `Automatically manage signing` (ou config manuelle selon votre process)

## 2) Verifier Google Sign-In iOS (option sans Firebase)

- Creer un OAuth Client iOS dans Google Cloud Console.
- Utiliser le bon `Bundle Identifier`.
- Ajouter le `REVERSED_CLIENT_ID` dans `Info.plist` (URL Types) si necessaire selon votre integration.

## 3) Installer dependances iOS

```bash
cd /Users/macbook/Desktop/Developer/Personnel/mbokatour_app_mobile
flutter clean
flutter pub get
cd ios
pod repo update
pod install
cd ..
```

## 4) Build Flutter release iOS

```bash
cd /Users/macbook/Desktop/Developer/Personnel/mbokatour_app_mobile
flutter build ios --release
```

## 5) Archive depuis Xcode (recommande pour distribution)

1. Ouvrir `ios/Runner.xcworkspace` dans Xcode.
2. Selectionner un device reel ou `Any iOS Device (arm64)`.
3. `Product` -> `Archive`.
4. Dans Organizer: `Distribute App` -> `App Store Connect` -> `Upload`.

## 6) Option CLI (archive/export)

Archive:
```bash
cd /Users/macbook/Desktop/Developer/Personnel/mbokatour_app_mobile/ios
xcodebuild \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  archive
```

Export IPA (necessite un `ExportOptions.plist` adapte):
```bash
xcodebuild \
  -exportArchive \
  -archivePath build/Runner.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/ipa
```

## 7) Artefacts de sortie

- Archive: `ios/build/Runner.xcarchive`
- IPA (si export CLI): `ios/build/ipa/*.ipa`

## 8) Verification post-upload

- App Store Connect -> TestFlight
- Attendre la processing Apple
- Ajouter testeurs internes/externe
- Publier la build

## 9) Notes securite

- Ne pas commit de secrets/signing sensibles.
- Documenter certificats/profils dans un coffre equipe.
