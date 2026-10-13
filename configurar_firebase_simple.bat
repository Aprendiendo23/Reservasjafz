@echo off
REM Script simple para configurar Firebase
REM Ejecuta este archivo haciendo doble clic

echo.
echo ========================================
echo   Configuracion Automatica de Firebase
echo ========================================
echo.

REM Verificar si Node.js está instalado
where node >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Node.js no esta instalado.
    echo.
    echo Por favor instala Node.js desde: https://nodejs.org/
    echo Luego ejecuta este script nuevamente.
    echo.
    pause
    exit /b 1
)

echo [OK] Node.js encontrado
node --version

REM Verificar si Firebase CLI está instalado
where firebase >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [INFO] Instalando Firebase CLI...
    call npm install -g firebase-tools
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] No se pudo instalar Firebase CLI
        pause
        exit /b 1
    )
)

echo [OK] Firebase CLI encontrado
firebase --version

echo.
echo ========================================
echo   Iniciando configuracion...
echo ========================================
echo.

REM Iniciar sesión en Firebase
echo [PASO 1] Iniciando sesion en Firebase...
echo (Se abrira una ventana del navegador)
firebase login

REM Configurar proyecto
echo.
echo [PASO 2] Configurando proyecto...
firebase use recursostic-18bb8 --add

REM Desplegar reglas e índices
echo.
echo [PASO 3] Desplegando reglas e indices...
firebase deploy --only firestore

echo.
echo ========================================
echo   Configuracion completada!
echo ========================================
echo.
echo Proximos pasos:
echo 1. Crea un usuario administrador en Firebase Console
echo 2. Consulta INSTRUCCIONES_RAPIDAS.md para mas detalles
echo.
pause

