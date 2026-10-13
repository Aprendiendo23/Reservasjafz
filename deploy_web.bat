@echo off
REM Script para compilar y desplegar la aplicación web a Firebase Hosting

echo ========================================
echo   Compilando y Desplegando Aplicacion Web
echo ========================================
echo.

REM Verificar que Flutter esté instalado
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter no esta instalado o no esta en el PATH
    pause
    exit /b 1
)

REM Verificar que Firebase CLI esté instalado
where firebase >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Firebase CLI no esta instalado
    echo Instala con: npm install -g firebase-tools
    pause
    exit /b 1
)

echo [1/3] Compilando aplicacion web (Release)...
flutter build web --release

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: La compilacion fallo
    pause
    exit /b 1
)

echo.
echo [2/3] Verificando configuracion de Firebase...
if not exist "firebase.json" (
    echo ADVERTENCIA: firebase.json no encontrado. Inicializando Firebase Hosting...
    firebase init hosting
)

echo.
echo [3/3] Desplegando a Firebase Hosting...
firebase deploy --only hosting

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo   Despliegue completado exitosamente!
    echo ========================================
    echo.
    echo Tu aplicacion esta disponible en:
    echo    https://recursostic-18bb8.web.app
    echo    https://recursostic-18bb8.firebaseapp.com
    echo.
) else (
    echo.
    echo ERROR: El despliegue fallo
    pause
    exit /b 1
)

pause
