# 🚀 Instrucciones para Desplegar la Aplicación Web

## ✅ Estado Actual

**La aplicación web ya está compilada y lista para desplegar.**

Los archivos están en: `build/web/`

---

## 📋 Opción 1: Desplegar con Firebase CLI (Recomendado)

### Paso 1: Instalar Firebase CLI

Cuando tengas mejor conexión a internet, ejecuta:

```bash
# Opción A: Instalación global (requiere sudo)
sudo npm install -g firebase-tools

# Opción B: Instalación local (sin permisos de admin)
npm install firebase-tools --save-dev
```

Si usas la opción B (local), luego ejecuta los comandos con:
```bash
npx firebase [comando]
```

### Paso 2: Iniciar sesión en Firebase

```bash
firebase login
```

Se abrirá una ventana del navegador para autenticarte.

### Paso 3: Configurar el proyecto (si es necesario)

```bash
firebase use recursostic-18bb8 --add
```

### Paso 4: Desplegar

```bash
# Si Firebase CLI está instalado globalmente:
firebase deploy --only hosting

# Si Firebase CLI está instalado localmente:
npx firebase deploy --only hosting
```

---

## 🌐 Opción 2: Desplegar desde Firebase Console (Sin CLI)

Si tienes problemas con la instalación de Firebase CLI, puedes desplegar manualmente:

### Paso 1: Comprimir los archivos

```bash
cd build/web
zip -r ../reservas_recursos_web.zip .
cd ../..
```

### Paso 2: Subir a Firebase Hosting

1. Ve a: https://console.firebase.google.com/project/recursostic-18bb8/hosting
2. Si es la primera vez, haz clic en "Comenzar"
3. Haz clic en "Agregar sitio web"
4. Ingresa un nombre para tu sitio (ej: `reservas-recursos`)
5. Haz clic en "Continuar"
6. En la sección "Hosting", haz clic en "Agregar archivo" o "Arrastrar y soltar"
7. Sube el archivo ZIP o los archivos individuales de `build/web/`
8. Haz clic en "Desplegar"

**Nota:** Esta opción es más manual pero funciona sin necesidad de CLI.

---

## 🔧 Opción 3: Usar el Script Automático

Una vez que Firebase CLI esté instalado, puedes usar el script:

```bash
# Linux/Mac
./deploy_web.sh

# Windows
deploy_web.bat
```

---

## 📍 Verificar el Despliegue

Después de desplegar, tu aplicación estará disponible en:

- **URL principal:** https://recursostic-18bb8.web.app
- **URL alternativa:** https://recursostic-18bb8.firebaseapp.com

---

## 🔍 Verificar Archivos Compilados

Los archivos ya están compilados en `build/web/`:

```bash
ls -lh build/web/
```

Deberías ver:
- `index.html` - Página principal
- `main.dart.js` - Código JavaScript compilado
- `assets/` - Recursos de la aplicación
- `canvaskit/` - Motor de renderizado
- `manifest.json` - Configuración PWA

---

## ⚠️ Solución de Problemas

### Error: "Firebase CLI no encontrado"
- Instala Firebase CLI con `npm install -g firebase-tools`
- O usa `npx firebase` si está instalado localmente

### Error: "No estás autenticado"
- Ejecuta `firebase login`

### Error: "Proyecto no configurado"
- Ejecuta `firebase use recursostic-18bb8 --add`

### Problemas de red con npm
- Espera a tener mejor conexión
- O usa la Opción 2 (Firebase Console web)

---

## 📝 Próximos Pasos

1. **Instalar Firebase CLI** cuando tengas mejor conexión
2. **Iniciar sesión** con `firebase login`
3. **Desplegar** con `firebase deploy --only hosting`
4. **Compartir la URL** con tus usuarios

---

## 🎯 Resumen Rápido

```bash
# 1. Instalar Firebase CLI (cuando tengas conexión estable)
sudo npm install -g firebase-tools

# 2. Iniciar sesión
firebase login

# 3. Desplegar
firebase deploy --only hosting
```

¡Tu aplicación web está lista para desplegar! 🎉
