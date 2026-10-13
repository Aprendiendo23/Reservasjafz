# Script simple para verificar e iniciar Firebase
Write-Host "🔥 Verificando Firebase..." -ForegroundColor Cyan
Write-Host ""

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

# Si no está instalado, intentar instalarlo
if (-not $firebaseInstalled) {
    Write-Host "⚠️  Firebase CLI no está instalado." -ForegroundColor Yellow
    
    # Verificar Node.js
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
    
    if ($nodeInstalled) {
        Write-Host "📥 Instalando Firebase CLI..." -ForegroundColor Cyan
        npm install -g firebase-tools
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Firebase CLI instalado" -ForegroundColor Green
            $firebaseInstalled = $true
        } else {
            Write-Host "❌ Error al instalar Firebase CLI" -ForegroundColor Red
            Write-Host "   Intenta ejecutar manualmente: npm install -g firebase-tools" -ForegroundColor Yellow
            exit
        }
    } else {
        Write-Host "❌ Node.js no está instalado." -ForegroundColor Red
        Write-Host "   Por favor instala Node.js desde: https://nodejs.org/" -ForegroundColor Yellow
        exit
    }
}

Write-Host ""
Write-Host "🔐 Iniciando sesión en Firebase..." -ForegroundColor Cyan
Write-Host "   (Se abrirá una ventana del navegador para autenticarte)" -ForegroundColor Yellow
Write-Host ""

# Iniciar sesión
firebase login

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Sesión iniciada correctamente" -ForegroundColor Green
    Write-Host ""
    
    # Listar proyectos disponibles
    Write-Host "📋 Proyectos disponibles:" -ForegroundColor Cyan
    firebase projects:list
    
    Write-Host ""
    Write-Host "🔧 Configurando proyecto recursostic-18bb8..." -ForegroundColor Cyan
    firebase use recursostic-18bb8 --add
    
    Write-Host ""
    Write-Host "✅ Configuración completada!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📝 Próximos pasos:" -ForegroundColor Cyan
    Write-Host "   1. Ejecuta: firebase deploy --only firestore" -ForegroundColor Yellow
    Write-Host "   2. O ejecuta: .\configurar_firebase.ps1" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "❌ Error al iniciar sesión" -ForegroundColor Red
    Write-Host "   Verifica tu conexión a internet y tu cuenta de Google" -ForegroundColor Yellow
}
