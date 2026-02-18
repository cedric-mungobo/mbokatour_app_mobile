Pour Android - Empreinte SHA-1
L'empreinte SHA-1 est générée à partir de votre keystore. Voici comment l'obtenir :

1. Pour le keystore de debug (développement) :


cd android
./gradlew signingReport


Ou avec keytool directement :

keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android



Pour le keystore de production (release) :
Si vous avez déjà créé un keystore de production :


keytool -list -v -keystore /chemin/vers/votre/keystore.jks -alias votre_alias


🔧 Résumé des commandes utiles :


# SHA-1 Android (debug)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Voir le Bundle ID iOS
grep -A 1 "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj

# Localisation du Info.plist
# Fichier : ios/Runner/Info.plist