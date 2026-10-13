# 🚀 Desplegar Cloud Functions para Notificaciones Push

## ✅ Lo que ya está configurado

- ✅ Carpeta `functions/` creada
- ✅ `package.json` con dependencias instaladas
- ✅ `index.js` con la función para enviar notificaciones push
- ✅ `firebase.json` actualizado para incluir functions

## 📋 Pasos para Desplegar

### 1. Verificar que estás autenticado en Firebase

```bash
firebase login
```

Si no tienes Firebase CLI instalado:
```bash
npm install -g firebase-tools
```

### 2. Verificar el proyecto de Firebase

```bash
firebase projects:list
```

Si necesitas seleccionar el proyecto:
```bash
firebase use recursostic-18bb8
```

### 3. Desplegar las funciones

```bash
cd /home/antonio/Documentos/reservas_recursos
firebase deploy --only functions
```

O desde la carpeta functions:
```bash
cd functions
npm run deploy
```

### 4. Verificar el despliegue

Después del despliegue, verás algo como:
```
✔  functions[sendPushNotifications] Successful create operation.
✔  functions[sendPushNotificationsManual] Successful create operation.
```

## 🧪 Probar las Notificaciones

### Opción 1: Crear una reserva desde la app
1. Abre la app en un dispositivo
2. Inicia sesión como docente
3. Crea una reserva
4. Todos los demás usuarios deberían recibir una notificación push

### Opción 2: Verificar en Firebase Console
1. Ve a Firebase Console > Functions
2. Deberías ver las funciones desplegadas
3. Ve a Firestore > `push_notifications_queue`
4. Cuando se cree una reserva, verás un nuevo documento
5. El documento se marcará como `procesado: true` cuando se envíen las notificaciones

## 📊 Monitorear las Funciones

### Ver logs en tiempo real:
```bash
firebase functions:log
```

### Ver logs de una función específica:
```bash
firebase functions:log --only sendPushNotifications
```

## 🔧 Solución de Problemas

### Error: "Functions requires Node.js 18"
Si tienes Node.js 20, puedes actualizar el `package.json`:
```json
"engines": {
  "node": "20"
}
```

### Error: "Permission denied"
Asegúrate de tener permisos de administrador en el proyecto de Firebase.

### Las notificaciones no se envían
1. Verifica que los tokens FCM estén guardados en `fcm_tokens`
2. Verifica los logs de Cloud Functions
3. Asegúrate de que los usuarios hayan dado permisos de notificaciones

## 📝 Estructura de la Función

La función `sendPushNotifications` se ejecuta automáticamente cuando:
- Se crea un documento en `push_notifications_queue`
- El documento tiene `procesado: false`

La función:
1. Lee los tokens FCM del documento
2. Envía notificaciones push a todos los tokens
3. Marca el documento como procesado
4. Elimina tokens inválidos de Firestore

## ✅ Verificación Final

Después del despliegue, verifica:

1. **Firebase Console > Functions**
   - Deberías ver `sendPushNotifications` y `sendPushNotificationsManual`

2. **Crear una reserva de prueba**
   - Crea una reserva desde la app
   - Verifica en Firestore que se creó un documento en `push_notifications_queue`
   - Espera unos segundos
   - El documento debería marcarse como `procesado: true`

3. **Recibir notificación**
   - Abre la app en otro dispositivo (o cierra la app)
   - Deberías recibir una notificación push

## 🎉 ¡Listo!

Una vez desplegado, las notificaciones push funcionarán automáticamente cada vez que un docente cree una reserva.
