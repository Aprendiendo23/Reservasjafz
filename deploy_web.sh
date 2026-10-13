#!/bin/bash
# Script para compilar y desplegar la aplicación web a Firebase Hosting

echo "========================================"
echo "  Compilando y Desplegando Aplicación Web"
echo "========================================"
echo ""

# Verificar que Flutter esté instalado
if ! command -v flutter &> /dev/null; then
    echo "❌ ERROR: Flutter no está instalado o no está en el PATH"
    exit 1
fi

# Verificar que Firebase CLI esté instalado
if ! command -v firebase &> /dev/null; then
    echo "❌ ERROR: Firebase CLI no está instalado"
    echo "Instala con: npm install -g firebase-tools"
    exit 1
fi

echo "[1/3] Compilando aplicación web (Release)..."
flutter build web --release

if [ $? -ne 0 ]; then
    echo "❌ ERROR: La compilación falló"
    exit 1
fi

echo ""
echo "[2/3] Verificando configuración de Firebase..."
if [ ! -f "firebase.json" ]; then
    echo "⚠️  firebase.json no encontrado. Inicializando Firebase Hosting..."
    firebase init hosting
fi

echo ""
echo "[3/3] Desplegando a Firebase Hosting..."
firebase deploy --only hosting

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "  ✅ Despliegue completado exitosamente!"
    echo "========================================"
    echo ""
    echo "🌐 Tu aplicación está disponible en:"
    echo "   https://recursostic-18bb8.web.app"
    echo "   https://recursostic-18bb8.firebaseapp.com"
    echo ""
else
    echo ""
    echo "❌ ERROR: El despliegue falló"
    exit 1
fi
