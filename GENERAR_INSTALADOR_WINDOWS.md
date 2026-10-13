# Generar Instalador .exe para Windows

Este documento explica cómo crear un instalador ejecutable (.exe) para Windows de tu aplicación Flutter.

## Opción 1: Compilar solo el .exe (sin instalador)

### Pasos rápidos:

1. **Ejecuta el script:**
   ```bash
   build_windows_exe.bat
   ```

2. **O manualmente:**
   ```bash
   flutter clean
   flutter pub get
   flutter build windows --release
   ```

3. **El ejecutable estará en:**
   ```
   build\windows\x64\runner\Release\reservas_recursos.exe
   ```

### Nota importante:
El .exe generado necesita todos los archivos de la carpeta `Release` para funcionar. Debes distribuir toda la carpeta o crear un instalador.

---

## Opción 2: Crear un Instalador con Inno Setup (Recomendado)

Inno Setup es gratuito y fácil de usar para crear instaladores profesionales.

### Paso 1: Instalar Inno Setup

1. Descarga Inno Setup desde: https://jrsoftware.org/isdl.php
2. Instálalo en tu computadora

### Paso 2: Crear el script de instalación

1. Abre Inno Setup Compiler
2. Ve a `File > New` o usa el asistente
3. Configura:
   - **Application name:** Reservas de Recursos
   - **Application version:** 1.0.0
   - **Application publisher:** Tu nombre/empresa
   - **Application website:** (opcional)
   - **Application folder:** `{pf}\ReservasRecursos`
   - **Application executable:** `reservas_recursos.exe`

### Paso 3: Configurar archivos a incluir

En la sección `[Files]`, agrega:

```ini
[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
```

### Paso 4: Compilar el instalador

1. Guarda el script como `instalador.iss`
2. Compila con `Build > Compile` (F9)
3. El instalador estará en `Output\`

---

## Opción 3: Crear Instalador con NSIS

NSIS (Nullsoft Scriptable Install System) es otra opción gratuita.

### Paso 1: Instalar NSIS

1. Descarga desde: https://nsis.sourceforge.io/Download
2. Instálalo

### Paso 2: Crear script básico

Crea un archivo `instalador.nsi`:

```nsis
!define APP_NAME "Reservas de Recursos"
!define APP_VERSION "1.0.0"
!define APP_PUBLISHER "Tu Nombre"
!define APP_EXECUTABLE "reservas_recursos.exe"

Name "${APP_NAME}"
OutFile "ReservasRecursos_Instalador.exe"
InstallDir "$PROGRAMFILES\ReservasRecursos"
RequestExecutionLevel admin

Section "Install"
    SetOutPath "$INSTDIR"
    File /r "build\windows\x64\runner\Release\*"
    
    CreateShortcut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_EXECUTABLE}"
    CreateShortcut "$SMPROGRAMS\${APP_NAME}.lnk" "$INSTDIR\${APP_EXECUTABLE}"
SectionEnd
```

### Paso 3: Compilar

1. Abre NSIS
2. Carga `instalador.nsi`
3. Compila (F9)

---

## Opción 4: Usar MSIX (Windows 10/11)

MSIX es el formato moderno de Microsoft.

### Requisitos:
- Windows 10 versión 1809 o superior
- Windows SDK

### Pasos:

1. **Instala el Windows SDK** (si no lo tienes)

2. **Compila la aplicación:**
   ```bash
   flutter build windows --release
   ```

3. **Usa MSIX Packaging Tool:**
   - Descarga desde Microsoft Store
   - Crea un nuevo paquete
   - Selecciona la carpeta `build\windows\x64\runner\Release`
   - Configura la información de la app
   - Genera el .msix

---

## Distribución

### Para distribuir solo el .exe:
- Copia toda la carpeta `Release` completa
- O comprime en un ZIP con todas las DLLs y archivos necesarios

### Para distribuir con instalador:
- Usa el .exe generado por Inno Setup o NSIS
- Es más profesional y fácil de instalar

---

## Solución de Problemas

### Error: "No se puede encontrar MSBuild"
- Instala Visual Studio con soporte para C++
- O instala solo "Build Tools for Visual Studio"

### Error: "Flutter no está en el PATH"
- Agrega Flutter al PATH del sistema
- O usa la ruta completa: `C:\flutter\bin\flutter.bat build windows`

### El .exe no funciona en otra computadora
- Asegúrate de incluir todas las DLLs
- O mejor: crea un instalador que incluya todo automáticamente

---

## Recomendación

**Usa Inno Setup** porque:
- ✅ Es gratuito
- ✅ Fácil de usar
- ✅ Crea instaladores profesionales
- ✅ Incluye desinstalador automático
- ✅ Soporta actualizaciones

