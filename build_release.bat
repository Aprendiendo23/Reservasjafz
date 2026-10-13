@echo off
echo ========================================
echo Compilando aplicacion para Windows
echo ========================================
echo.
echo Esto puede tardar varios minutos...
echo.

flutter build windows --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Compilacion completada exitosamente!
    echo ========================================
    echo.
    echo El ejecutable se encuentra en:
    echo build\windows\x64\runner\Release\reservas_recursos.exe
    echo.
    echo Puedes ejecutarlo directamente desde esa ubicacion.
    echo.
) else (
    echo.
    echo ========================================
    echo Error en la compilacion
    echo ========================================
    echo.
    echo Revisa los errores anteriores.
    echo.
)

pause













