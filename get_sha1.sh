#!/bin/bash

# Script pour obtenir les empreintes SHA-1 pour Android
# Mbokatour App

KEYTOOL="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"
DEBUG_KEYSTORE="$HOME/.android/debug.keystore"
RELEASE_KEYSTORE="$HOME/mbokatour-release-key.jks"

echo "=========================================="
echo "Empreintes SHA-1 pour Mbokatour App"
echo "=========================================="
echo ""

# SHA-1 Debug
echo "📱 SHA-1 DEBUG (pour développement) :"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f "$DEBUG_KEYSTORE" ]; then
    "$KEYTOOL" -list -v -keystore "$DEBUG_KEYSTORE" -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep "SHA1:" | head -1
    echo ""
else
    echo "❌ Keystore debug non trouvé à : $DEBUG_KEYSTORE"
    echo ""
fi

# SHA-1 Release
echo "🔐 SHA-1 RELEASE (pour production) :"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f "$RELEASE_KEYSTORE" ]; then
    echo "⚠️  Vous devrez entrer le mot de passe du keystore :"
    "$KEYTOOL" -list -v -keystore "$RELEASE_KEYSTORE" -alias mbokatour 2>/dev/null | grep "SHA1:" | head -1
    echo ""
else
    echo "❌ Keystore release non trouvé à : $RELEASE_KEYSTORE"
    echo "💡 Générez-le d'abord avec : ./generate_keystore.sh"
    echo ""
fi

echo "=========================================="
echo "📋 Utilisation :"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Copiez le SHA-1 DEBUG pour Firebase (développement)"
echo "2. Copiez le SHA-1 RELEASE pour Firebase (production)"
echo "3. Ajoutez les deux dans Firebase Console :"
echo "   Project Settings > Your apps > Android app > SHA certificate fingerprints"
echo "=========================================="

