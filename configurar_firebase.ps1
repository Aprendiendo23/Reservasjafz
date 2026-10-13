# Script de PowerShell para configurar Firebase automáticamente
# Ejecuta este script como administrador: .\configurar_firebase.ps1

Write-Host "🔥 Configurando Firebase automáticamente..." -ForegroundColor Cyan
Write-Host ""

# Verificar si Node.js está instalado
$nodeInstalled = $false
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        Write-Host "✅ Node.js encontrado: $nodeVersion" -ForegroundColor Green
        $nodeInstalled = $true
    }
} catch {
    $nodeInstalled = $false
}

# Instalar Node.js si no está instalado
if (-not $nodeInstalled) {
    Write-Host "⚠️  Node.js no está instalado." -ForegroundColor Yellow
    Write-Host "📥 Instalando Node.js..." -ForegroundColor Cyan
    
    # Descargar e instalar Node.js
    $nodeUrl = "https://nodejs.org/dist/v20.11.0/node-v20.11.0-x64.msi"
    $nodeInstaller = "$env:TEMP\nodejs-installer.msi"
    
    try {
        Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller
        Write-Host "📦 Ejecutando instalador de Node.js..." -ForegroundColor Cyan
        Start-Process msiexec.exe -ArgumentList "/i `"$nodeInstaller`" /quiet /norestart" -Wait
        Write-Host "✅ Node.js instalado. Por favor reinicia PowerShell y ejecuta este script nuevamente." -ForegroundColor Green
        exit
    } catch {
        Write-Host "❌ Error al instalar Node.js automáticamente." -ForegroundColor Red
            Write-Host "📝 Por favor instala Node.js manualmente desde: https://nodejs.org/" -ForegroundColor Yellow
        Write-Host "   Luego ejecuta este script nuevamente." -ForegroundColor Yellow
        exit
    } catch {
        Write-Host "❌ Error al instalar Node.js automáticamente." -ForegroundColor Red
        Write-Host "📝 Por favor instala Node.js manualmente desde: https://nodejs.org/" -ForegroundColor Yellow
        Write-Host "   Luego ejecuta este script nuevamente." -ForegroundColor Yellow
        exit
    }
}

# Verificar si Firebase CLI está instalado
$firebaseInstalled = $false
try {
    $firebaseVersion = firebase --version 2>$null
    if ($firebaseVersion) {
        Write-Host "✅ Firebase CLI encontrado: $firebaseVersion" -ForegroundColor Green
        $firebaseInstalled = $true
    }
} catch {
    $firebaseInstalled = $false
}

# Instalar Firebase CLI si no está instalado
if (-not $firebaseInstalled) {
    Write-Host "📥 Instalando Firebase CLI..." -ForegroundColor Cyan
    npm install -g firebase-tools
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Firebase CLI instalado correctamente" -ForegroundColor Green
    } else {
        Write-Host "❌ Error al instalar Firebase CLI" -ForegroundColor Red
        exit
    }
}

# Verificar que los archivos de configuración existen
if (-not (Test-Path "firestore.rules")) {
    Write-Host "❌ Error: No se encuentra firestore.rules" -ForegroundColor Red
    exit
}

if (-not (Test-Path "firestore.indexes.json")) {
    Write-Host "❌ Error: No se encuentra firestore.indexes.json" -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "📋 Archivos de configuración encontrados:" -ForegroundColor Cyan
Write-Host "   ✅ firestore.rules" -ForegroundColor Green
Write-Host "   ✅ firestore.indexes.json" -ForegroundColor Green
Write-Host ""

# Iniciar sesión en Firebase
Write-Host "🔐 Iniciando sesión en Firebase..." -ForegroundColor Cyan
Write-Host "   (Se abrirá una ventana del navegador para autenticarte)" -ForegroundColor Yellow
firebase login

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error al iniciar sesión en Firebase" -ForegroundColor Red
    exit
}

# Verificar si el proyecto está inicializado
if (-not (Test-Path ".firebaserc")) {
    Write-Host "📦 Inicializando proyecto Firebase..." -ForegroundColor Cyan
    Write-Host "   Selecciona el proyecto: recursostic-18bb8" -ForegroundColor Yellow
    firebase use recursostic-18bb8 --add
} else {
    Write-Host "✅ Proyecto Firebase ya está configurado" -ForegroundColor Green
    firebase use recursostic-18bb8
}

# Desplegar reglas e índices
Write-Host ""
Write-Host "🚀 Desplegando reglas e índices a Firebase..." -ForegroundColor Cyan
Write-Host ""

firebase deploy --only firestore

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ ¡Configuración completada exitosamente!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📝 Próximos pasos:" -ForegroundColor Cyan
    Write-Host "   1. Ve a Firebase Console y crea un usuario administrador" -ForegroundColor Yellow
    Write-Host "   2. Crea un documento en la colección 'usuarios' con rol 'admin'" -ForegroundColor Yellow
    Write-Host "   3. Consulta INSTRUCCIONES_RAPIDAS.md para más detalles" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Error al desplegar configuración" -ForegroundColor Red
    Write-Host "   Revisa los mensajes de error arriba" -ForegroundColor Yellow
    Write-Host ""
}

