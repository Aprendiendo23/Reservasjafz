#!/bin/bash

# Script para desplegar las reglas de Firestore
# Proyecto: recursostic-18bb8

echo "🔥 Desplegando reglas de Firestore..."
echo ""

# Verificar si Firebase CLI está disponible
if command -v firebase &> /dev/null || command -v npx &> /dev/null; then
    echo "✅ Firebase CLI encontrado"
    
    # Intentar desplegar con npx
    if command -v npx &> /dev/null; then
        echo "📦 Usando npx firebase-tools..."
        npx firebase-tools deploy --only firestore:rules --project recursostic-18bb8
    else
        echo "📦 Usando firebase CLI..."
        firebase deploy --only firestore:rules --project recursostic-18bb8
    fi
else
    echo "❌ Firebase CLI no encontrado"
    echo ""
    echo "📋 INSTRUCCIONES MANUALES:"
    echo ""
    echo "1. Abre tu navegador y ve a:"
    echo "   https://console.firebase.google.com/project/recursostic-18bb8/firestore/rules"
    echo ""
    echo "2. Copia TODO el contenido del archivo 'firestore.rules'"
    echo ""
    echo "3. Pega el contenido en el editor de reglas de Firebase Console"
    echo ""
    echo "4. Haz clic en el botón 'Publicar' (Publish)"
    echo ""
    echo "5. Espera 10-20 segundos para que se apliquen los cambios"
    echo ""
    echo "✅ Las reglas ahora incluyen permisos para:"
    echo "   - Grados/Aulas (CRUD completo para admins)"
    echo "   - Asignaturas (CRUD completo para admins)"
    echo ""
fi
