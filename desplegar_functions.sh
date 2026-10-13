#!/bin/bash

# Script para desplegar Cloud Functions
# Asegúrate de tener Firebase CLI instalado: npm install -g firebase-tools

echo "🚀 Desplegando Cloud Functions..."

# Verificar si Firebase CLI está instalado
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI no está instalado."
    echo "📦 Instalando Firebase CLI..."
    npm install -g firebase-tools
fi

# Verificar autenticación
echo "🔐 Verificando autenticación..."
firebase login --no-localhost 2>/dev/null || echo "⚠️ Ya estás autenticado o necesitas iniciar sesión"

# Verificar proyecto
echo "📦 Verificando proyecto de Firebase..."
firebase use recursostic-18bb8 2>/dev/null || echo "⚠️ Usa 'firebase use <project-id>' para seleccionar tu proyecto"

# Desplegar funciones
echo "📤 Desplegando funciones..."
firebase deploy --only functions

echo "✅ ¡Despliegue completado!"
echo ""
echo "📝 Próximos pasos:"
echo "   1. Crea una reserva desde la app"
echo "   2. Verifica en Firebase Console > Functions que se ejecutó"
echo "   3. Los usuarios deberían recibir notificaciones push"
