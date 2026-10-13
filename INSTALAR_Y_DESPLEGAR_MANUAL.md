# 📋 Guía Manual: Instalar y Desplegar Cloud Functions

## 🎯 Pasos a Seguir

### Paso 1: Instalar Firebase CLI

Abre tu terminal y ejecuta:

```bash
# Opción A: Instalar globalmente (requiere sudo)
sudo npm install -g firebase-tools

# O Opción B: Instalar localmente en el proyecto
cd /home/antonio/Documentos/reservas_recursos
npm install firebase-tools --save-dev
```

**Recomendación:** Usa la Opción A si tienes permisos de administrador.

### Paso 2: Verificar la Instalación

```bash
firebase --version
```

Deberías ver algo como: `15.5.1` o similar.

### Paso 3: Iniciar Sesión en Firebase

```bash
firebase login
```

Esto abrirá tu navegador para autenticarte. Sigue las instrucciones en pantalla.

**Si estás en un servidor sin navegador:**
```bash
firebase login --no-localhost
```
Te dará un código que debes ingresar en: https://accounts.google.com/o/oauth2/auth

### Paso 4: Seleccionar tu Proyecto

```bash
cd /home/antonio/Documentos/reservas_recursos
firebase use recursostic-18bb8
```

Si no conoces el ID de tu proyecto, puedes listarlos:
```bash
firebase projects:list
```

### Paso 5: Verificar que las Functions Están Listas

```bash
# Verificar que existe la carpeta functions
ls functions/

# Deberías ver:
# - index.js
# - package.json
# - node_modules/
```

### Paso 6: Instalar Dependencias de Functions (si no están)

```bash
cd functions
npm install
cd ..
```

### Paso 7: Desplegar las Functions

```bash
# Desde la raíz del proyecto
firebase deploy --only functions
```

O si prefieres desplegar solo una función específica:
```bash
firebase deploy --only functions:sendPushNotifications
```

### Paso 8: Verificar el Despliegue

Después del despliegue, deberías ver algo como:

```
✔  functions[sendPushNotifications(us-central1)] Successful create operation.
✔  functions[sendPushNotificationsManual(us-central1)] Successful create operation.

✔  Deploy complete!
```

## ✅ Verificación Final

1. **En Firebase Console:**
   - Ve a: https://console.firebase.google.com
   - Selecciona tu proyecto: `recursostic-18bb8`
   - Ve a: **Functions** (en el menú lateral)
   - Deberías ver 2 funciones:
     - `sendPushNotifications`
     - `sendPushNotificationsManual`

2. **Probar las notificaciones:**
   - Abre tu app Flutter
   - Crea una reserva como docente
   - Los demás usuarios deberían recibir notificaciones push

## 🔧 Solución de Problemas Comunes

### Error: "firebase: command not found"
**Solución:**
```bash
# Si instalaste localmente, usa:
npx firebase --version

# O agrega al PATH:
export PATH=$PATH:./node_modules/.bin
```

### Error: "Permission denied" al instalar globalmente
**Solución:**
```bash
# Usa sudo (si tienes permisos)
sudo npm install -g firebase-tools

# O instala localmente sin sudo
npm install firebase-tools --save-dev
```

### Error: "Functions requires Node.js 18"
**Solución:**
Ya está configurado para Node.js 20 en `functions/package.json`. Si persiste:
```bash
cd functions
# Edita package.json y cambia "node": "20"
npm install
```

### Error: "Not authenticated"
**Solución:**
```bash
firebase login
# Sigue las instrucciones en el navegador
```

### Error: "Project not found"
**Solución:**
```bash
# Lista tus proyectos
firebase projects:list

# Selecciona el correcto
firebase use <tu-project-id>
```

## 📝 Comandos Rápidos (Copia y Pega)

```bash
# 1. Instalar Firebase CLI
sudo npm install -g firebase-tools

# 2. Iniciar sesión
firebase login

# 3. Ir al proyecto
cd /home/antonio/Documentos/reservas_recursos

# 4. Seleccionar proyecto
firebase use recursostic-18bb8

# 5. Instalar dependencias de functions (si es necesario)
cd functions && npm install && cd ..

# 6. Desplegar
firebase deploy --only functions
```

## 🎉 ¡Listo!

Una vez desplegado, las notificaciones push funcionarán automáticamente cada vez que un docente cree una reserva.
