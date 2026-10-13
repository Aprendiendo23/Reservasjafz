@echo off
echo ========================================
echo Desplegando indices de Firestore
echo ========================================
echo.

firebase deploy --only firestore:indexes

echo.
echo ========================================
echo Proceso completado
echo ========================================
echo.
echo NOTA: Los indices pueden tardar unos minutos en crearse.
echo Puedes verificar el estado en Firebase Console.
echo.
pause













