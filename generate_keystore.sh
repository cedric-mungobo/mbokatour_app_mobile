#!/bin/bash

# Script pour générer le keystore de production pour Android
# Mbokatour App

KEYTOOL="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"
KEYSTORE_PATH="$HOME/mbokatour-release-key.jks"
ALIAS="mbokatour"

echo "=========================================="
echo "Génération du Keystore de Production"
echo "=========================================="
echo ""
echo "Informations requises :"
echo "- Mot de passe du keystore (à retenir !)"
echo "- Nom et prénom"
echo "- Nom de l'organisation"
echo "- Ville"
echo "- Province/État"
echo "- Code pays (ex: CD pour Congo)"
echo ""
echo "Le keystore sera créé à : $KEYSTORE_PATH"
echo ""

"$KEYTOOL" -genkey -v -keystore "$KEYSTORE_PATH" -keyalg RSA -keysize 2048 -validity 10000 -alias "$ALIAS"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Keystore créé avec succès !"
    echo ""
    echo "📍 Emplacement : $KEYSTORE_PATH"
    echo "🔑 Alias : $ALIAS"
    echo ""
    echo "⚠️  IMPORTANT : Sauvegardez ce fichier et le mot de passe en lieu sûr !"
    echo ""
    echo "Pour obtenir l'empreinte SHA-1 :"
    echo "\"$KEYTOOL\" -list -v -keystore \"$KEYSTORE_PATH\" -alias $ALIAS"
else
    echo ""
    echo "❌ Erreur lors de la création du keystore"
fi

