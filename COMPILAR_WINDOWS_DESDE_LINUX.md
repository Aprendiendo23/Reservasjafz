# Compilar .exe para Windows desde Linux

## Problema
Flutter no permite compilar para Windows desde Linux directamente. El mensaje de error es:
```
"build windows" only supported on Windows hosts.
```

## Soluciones

### Opción 1: GitHub Actions (Recomendado) ⭐

Esta es la forma más fácil y automática. GitHub Actions compilará tu aplicación en un servidor Windows automáticamente.

#### Pasos:

1. **Sube tu código a GitHub** (si aún no lo has hecho):
   ```bash
   git add .
   git commit -m "Preparar para compilación Windows"
   git push origin main
   ```

2. **Ve a tu repositorio en GitHub** → pestaña **Actions**

3. **Ejecuta el workflow manualmente**:
   - Haz clic en "Build Windows Executable"
   - Haz clic en "Run workflow"
   - Selecciona la rama (main/master)
   - Haz clic en "Run workflow"

4. **Espera a que termine** (5-10 minutos)

5. **Descarga el artefacto**:
   - Cuando termine, haz clic en el workflow completado
   - En la sección "Artifacts", descarga `reservas-recursos-windows`
   - Descomprime el ZIP y tendrás el `.exe` y todos los archivos necesarios

#### Ventajas:
- ✅ No necesitas una máquina Windows
- ✅ Automático y gratuito
- ✅ Se ejecuta en la nube
- ✅ Puedes programarlo para que se ejecute automáticamente

---

### Opción 2: Máquina Virtual Windows

Si tienes una máquina virtual con Windows:

1. **Instala Flutter en Windows**
2. **Copia tu proyecto** a la VM
3. **Ejecuta**:
   ```bash
   flutter build windows --release
   ```

---

### Opción 3: Máquina Windows Física

Si tienes acceso a una computadora con Windows:

1. **Clona o copia el proyecto** a Windows
2. **Instala Flutter** en Windows
3. **Ejecuta**:
   ```bash
   flutter build windows --release
   ```

---

### Opción 4: Usar un Servicio de CI/CD

Otras opciones similares a GitHub Actions:
- **GitLab CI/CD** (con runners Windows)
- **AppVeyor** (especializado en Windows)
- **Azure Pipelines** (con agentes Windows)

---

## Estructura del Archivo Generado

Después de compilar, tendrás:

```
Release/
├── reservas_recursos.exe  ← Ejecutable principal
├── data/                   ← Recursos de la app
├── flutter_windows.dll     ← DLLs necesarios
└── ... (otros DLLs)
```

**Importante:** Para distribuir la app, necesitas copiar **toda la carpeta Release**, no solo el .exe

---

## Notas

- **Primera compilación:** Puede tardar 10-20 minutos
- **Compilaciones posteriores:** 2-5 minutos
- **Tamaño total:** ~50-100 MB
- **Requisitos:** Windows 10/11 (64-bit)

---

## Solución de Problemas

### Error en GitHub Actions:
- Verifica que el workflow esté en `.github/workflows/build-windows.yml`
- Revisa los logs en la pestaña "Actions" de GitHub

### El .exe no funciona en otra PC:
- Asegúrate de copiar **toda la carpeta Release**, no solo el .exe
- La PC destino necesita Visual C++ Redistributable (generalmente ya está instalado)
