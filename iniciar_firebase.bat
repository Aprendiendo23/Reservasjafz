@echo off
echo ========================================
echo   Iniciando Firebase
echo ========================================
echo.

REM Verificar si Firebase CLI está instalado
where firebase >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [INFO] Firebase CLI no esta instalado.
    echo.
    
    REM Verificar Node.js
    where node >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Node.js no esta instalado.
        echo.
        echo Por favor instala Node.js desde: https://nodejs.org/
        echo Luego ejecuta este script nuevamente.
        pause
        exit /b 1
    )
    
    echo [INFO] Node.js encontrado
    node --version
    echo.
    echo [INFO] Instalando Firebase CLI...
    call npm install -g firebase-tools
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] No se pudo instalar Firebase CLI
        pause
        exit /b 1
    )
    echo.
)

echo [OK] Firebase CLI encontrado
firebase --version
echo.

echo ========================================
echo   Iniciando sesion en Firebase
echo ========================================
echo.
echo Se abrira una ventana del navegador para autenticarte
echo.
pause

firebase login

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [OK] Sesion iniciada correctamente
    echo.
    echo [INFO] Listando proyectos disponibles...
    firebase projects:list
    echo.
    echo [INFO] Configurando proyecto recursostic-18bb8...
    firebase use recursostic-18bb8 --add
    echo.
    echo ========================================
    echo   Configuracion completada!
    echo ========================================
    echo.
    echo Proximos pasos:
    echo 1. Ejecuta: firebase deploy --only firestore
    echo 2. O ejecuta: configurar_firebase_simple.bat
    echo.
) else (
    echo.
    echo [ERROR] Error al iniciar sesion
    echo Verifica tu conexion a internet y tu cuenta de Google
    echo.
)

pause

