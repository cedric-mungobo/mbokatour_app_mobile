# Guide de Configuration - Mbokatour App

## ✅ Modifications effectuées

### 📱 Android
- **Application ID** : `com.mbokatour`
- **Namespace** : `com.mbokatour`
- **Package Kotlin** : `com.mbokatour`

### 🍎 iOS
- **Bundle ID** : `com.mbokatour`
- **Bundle ID Tests** : `com.mbokatour.RunnerTests`

---

## 🔐 Configuration du Keystore Android (Production)

### Étape 1 : Générer le Keystore

Exécutez le script fourni :

```bash
./generate_keystore.sh
```

Vous devrez fournir :
- **Mot de passe du keystore** (minimum 6 caractères)
- **Mot de passe de la clé** (peut être identique au keystore)
- **Nom et prénom**
- **Nom de l'organisation** (ex: Mbokatour)
- **Ville** (ex: Kinshasa)
- **Province/État** (ex: Kinshasa)
- **Code pays** (ex: CD pour Congo)

⚠️ **IMPORTANT** : Sauvegardez le fichier `~/mbokatour-release-key.jks` et les mots de passe en lieu sûr !

### Étape 2 : Créer le fichier key.properties

Copiez le fichier exemple :

```bash
cp android/key.properties.example android/key.properties
```

Éditez `android/key.properties` avec vos informations :

```properties
storePassword=VOTRE_MOT_DE_PASSE_KEYSTORE
keyPassword=VOTRE_MOT_DE_PASSE_CLE
keyAlias=mbokatour
storeFile=/Users/VOTRE_NOM_UTILISATEUR/mbokatour-release-key.jks
```

Remplacez :
- `VOTRE_MOT_DE_PASSE_KEYSTORE` par le mot de passe du keystore
- `VOTRE_MOT_DE_PASSE_CLE` par le mot de passe de la clé
- `VOTRE_NOM_UTILISATEUR` par votre nom d'utilisateur macOS

### Étape 3 : Obtenir l'empreinte SHA-1

Pour Firebase, Google Sign-In, etc. :

```bash
/Applications/Android\ Studio.app/Contents/jbr/Contents/Home/bin/keytool -list -v -keystore ~/mbokatour-release-key.jks -alias mbokatour
```

Ou pour le keystore de debug :

```bash
/Applications/Android\ Studio.app/Contents/jbr/Contents/Home/bin/keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

---

## 📦 Build de Production

### Android (APK)
```bash
flutter build apk --release
```

### Android (App Bundle pour Google Play)
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

---

## 🔍 Vérification des Identifiants

### Android
```bash
# Voir l'Application ID
grep "applicationId" android/app/build.gradle.kts

# Voir le namespace
grep "namespace" android/app/build.gradle.kts
```

### iOS
```bash
# Voir le Bundle ID
grep -A 1 "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj
```

---

## 📝 Fichiers Importants

- `android/key.properties` - Configuration du keystore (NE PAS COMMITER)
- `~/mbokatour-release-key.jks` - Keystore de production (SAUVEGARDER)
- `android/app/build.gradle.kts` - Configuration Android
- `ios/Runner.xcodeproj/project.pbxproj` - Configuration iOS
- `ios/Runner/Info.plist` - Informations de l'app iOS

---

## ⚠️ Sécurité

✅ Le fichier `key.properties` est déjà dans `.gitignore`  
✅ Les fichiers `.jks` et `.keystore` sont déjà dans `.gitignore`  
❌ **NE JAMAIS** commiter ces fichiers dans Git  
✅ Sauvegardez le keystore dans un endroit sûr (cloud privé, coffre-fort)

---

## 🚀 Prochaines Étapes

1. Générer le keystore avec `./generate_keystore.sh`
2. Créer et configurer `android/key.properties`
3. Obtenir les empreintes SHA-1 (debug et release)
4. Configurer Firebase avec les SHA-1
5. Tester le build de production

