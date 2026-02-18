# Configuration Android & iOS - Mbokatour App

## 📋 Résumé des Modifications

### ✅ Android
- **Application ID** : `com.mbokatour` ✓
- **Namespace** : `com.mbokatour` ✓
- **Package** : `com.mbokatour` ✓
- **Signing** : Configuré pour production ✓

### ✅ iOS
- **Bundle ID** : `com.mbokatour` ✓
- **Bundle ID Tests** : `com.mbokatour.RunnerTests` ✓

---

## 🚀 Guide de Démarrage Rapide

### 1️⃣ Générer le Keystore Android (Production)

```bash
./generate_keystore.sh
```

**Informations à fournir :**
- Mot de passe du keystore (ex: `Mbokatour2024!`)
- Mot de passe de la clé (peut être identique)
- Nom : `Votre Nom`
- Organisation : `Mbokatour`
- Ville : `Kinshasa`
- Province : `Kinshasa`
- Code pays : `CD`

⚠️ **Sauvegardez le fichier `~/mbokatour-release-key.jks` et les mots de passe !**

---

### 2️⃣ Configurer le Signing Android

```bash
# Copier le fichier exemple
cp android/key.properties.example android/key.properties

# Éditer avec vos informations
nano android/key.properties
```

**Contenu de `android/key.properties` :**
```properties
storePassword=VotreMdpKeystore
keyPassword=VotreMdpCle
keyAlias=mbokatour
storeFile=/Users/VOTRE_NOM_UTILISATEUR/mbokatour-release-key.jks
```

---

### 3️⃣ Obtenir les Empreintes SHA-1

```bash
./get_sha1.sh
```

Vous obtiendrez :
- **SHA-1 DEBUG** : Pour le développement et les tests
- **SHA-1 RELEASE** : Pour la production

**Utilisation :**
- Firebase Console → Project Settings → Your apps → Android app
- Ajoutez les deux SHA-1 dans "SHA certificate fingerprints"

---

## 📱 Pour Android

### Obtenir le SHA-1 manuellement

**Debug (développement) :**
```bash
/Applications/Android\ Studio.app/Contents/jbr/Contents/Home/bin/keytool \
  -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android
```

**Release (production) :**
```bash
/Applications/Android\ Studio.app/Contents/jbr/Contents/Home/bin/keytool \
  -list -v \
  -keystore ~/mbokatour-release-key.jks \
  -alias mbokatour
```

### Build APK/AAB

```bash
# APK Debug
flutter build apk --debug

# APK Release
flutter build apk --release

# App Bundle (pour Google Play)
flutter build appbundle --release
```

---

## 🍎 Pour iOS

### Bundle ID
Le Bundle ID est déjà configuré : `com.mbokatour`

### Fichier Info.plist
Emplacement : `ios/Runner/Info.plist`

### Ouvrir dans Xcode
```bash
open ios/Runner.xcworkspace
```

Dans Xcode :
- **Runner** → **Signing & Capabilities**
- Vérifiez le **Bundle Identifier** : `com.mbokatour`
- Configurez votre **Team** pour le signing

### Build iOS
```bash
flutter build ios --release
```

---

## 🔍 Vérifications

### Vérifier l'Application ID Android
```bash
grep "applicationId" android/app/build.gradle.kts
# Résultat attendu: applicationId = "com.mbokatour"
```

### Vérifier le Bundle ID iOS
```bash
grep "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj | head -1
# Résultat attendu: PRODUCT_BUNDLE_IDENTIFIER = com.mbokatour;
```

---

## 📂 Fichiers Créés

- ✅ `generate_keystore.sh` - Script pour générer le keystore
- ✅ `get_sha1.sh` - Script pour obtenir les SHA-1
- ✅ `android/key.properties.example` - Exemple de configuration
- ✅ `CONFIGURATION_GUIDE.md` - Guide détaillé
- ✅ `SETUP_ANDROID_IOS.md` - Ce fichier

---

## ⚠️ Sécurité

**NE JAMAIS commiter dans Git :**
- ❌ `android/key.properties`
- ❌ `*.jks`
- ❌ `*.keystore`

**Ces fichiers sont déjà dans `.gitignore` ✓**

---

## 📞 Support

Pour toute question, consultez :
- [Documentation Flutter](https://docs.flutter.dev/)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [iOS Code Signing](https://developer.apple.com/support/code-signing/)

