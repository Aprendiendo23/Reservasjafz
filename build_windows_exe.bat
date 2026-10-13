@echo off
echo ========================================
echo Compilando aplicacion para Windows
echo ========================================
echo.

REM Verificar que Flutter este instalado
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter no esta instalado o no esta en el PATH
    echo Por favor instala Flutter y agrega al PATH
    pause
    exit /b 1
)

echo [1/4] Limpiando compilaciones anteriores...
flutter clean

echo.
echo [2/4] Obteniendo dependencias...
flutter pub get

echo.
echo [3/4] Compilando aplicacion para Windows (Release)...
flutter build windows --release

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: La compilacion fallo
    pause
    exit /b 1
)

echo.
echo [4/4] Compilacion completada exitosamente!
echo.
echo El ejecutable se encuentra en:
echo build\windows\x64\runner\Release\reservas_recursos.exe
echo.
echo Para crear un instalador, puedes usar Inno Setup o NSIS
echo.
echo Presiona cualquier tecla para abrir la carpeta...
pause >nul
explorer build\windows\x64\runner\Release

