# Generar Ejecutable (.exe) para Windows

## Requisitos Previos

1. **Flutter SDK** instalado y configurado
2. **Visual Studio** con herramientas de desarrollo de Windows
3. **Conexión a Internet** (para descargar dependencias)

## Pasos para Generar el .exe

### 1. Compilar la Aplicación

Ejecuta el siguiente comando en la terminal (puede tardar varios minutos):

```bash
flutter build windows --release
```

**Nota:** El flag `--release` genera una versión optimizada para producción.

### 2. Ubicación del Ejecutable

Una vez completada la compilación, el ejecutable se encontrará en:

```
build\windows\x64\runner\Release\reservas_recursos.exe
```

### 3. Distribuir la Aplicación

Para distribuir la aplicación, necesitas copiar toda la carpeta `Release` que contiene:
- `reservas_recursos.exe` (ejecutable principal)
- `data/` (recursos de la aplicación)
- Archivos DLL necesarios

## Opciones de Compilación

### Versión de Desarrollo (Debug)
```bash
flutter build windows
```
- Incluye información de depuración
- Archivo más grande
- Útil para desarrollo y pruebas

### Versión de Producción (Release)
```bash
flutter build windows --release
```
- Optimizada y comprimida
- Archivo más pequeño
- Mejor rendimiento
- **Recomendada para distribución**

## Crear Instalador (Opcional)

Si quieres crear un instalador profesional, puedes usar:

### Opción 1: Inno Setup (Recomendado)
1. Descarga [Inno Setup](https://jrsoftware.org/isdl.php)
2. Crea un script de instalación que incluya todos los archivos de la carpeta Release
3. Genera el instalador .exe

### Opción 2: NSIS (Nullsoft Scriptable Install System)
1. Descarga [NSIS](https://nsis.sourceforge.io/Download)
2. Crea un script de instalación
3. Compila el instalador

## Script Automático

Puedes crear un script para automatizar el proceso:

**build_release.bat:**
```batch
@echo off
echo Compilando aplicacion para Windows...
flutter build windows --release
echo.
echo Compilacion completada!
echo El ejecutable esta en: build\windows\x64\runner\Release\
pause
```

## Notas Importantes

1. **Primera compilación:** Puede tardar 10-20 minutos
2. **Compilaciones posteriores:** Son más rápidas (2-5 minutos)
3. **Tamaño del ejecutable:** Aproximadamente 50-100 MB con todas las dependencias
4. **Requisitos del sistema:** Windows 10 o superior (64-bit)

## Verificar la Compilación

Después de compilar, puedes probar el ejecutable ejecutando:

```bash
.\build\windows\x64\runner\Release\reservas_recursos.exe
```

## Solución de Problemas

### Error: "CMake not found"
- Instala Visual Studio con las herramientas de C++
- O instala CMake manualmente

### Error: "MSBuild not found"
- Asegúrate de tener Visual Studio instalado
- Ejecuta desde "Developer Command Prompt for VS"

### Error de dependencias
```bash
flutter pub get
flutter clean
flutter build windows --release
```

## Distribución

Para distribuir la aplicación:
1. Comprime toda la carpeta `Release` en un ZIP
2. O crea un instalador usando Inno Setup o NSIS
3. Incluye instrucciones de instalación si es necesario














