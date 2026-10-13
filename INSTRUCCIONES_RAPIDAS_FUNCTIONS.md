# ⚡ Instrucciones Rápidas: Desplegar Cloud Functions

## 🎯 Pasos Rápidos

### 1. Instalar Firebase CLI (si no lo tienes)
```bash
npm install -g firebase-tools
```

### 2. Iniciar sesión en Firebase
```bash
firebase login
```

### 3. Seleccionar el proyecto
```bash
firebase use recursostic-18bb8
```

### 4. Desplegar las funciones
```bash
cd /home/antonio/Documentos/reservas_recursos
firebase deploy --only functions
```

O usar el script:
```bash
./desplegar_functions.sh
```

## ✅ Verificación

Después del despliegue:

1. **Verifica en Firebase Console:**
   - Ve a https://console.firebase.google.com
   - Selecciona tu proyecto
   - Ve a Functions
   - Deberías ver `sendPushNotifications` y `sendPushNotificationsManual`

2. **Prueba creando una reserva:**
   - Abre la app
   - Crea una reserva como docente
   - Los demás usuarios deberían recibir una notificación push

3. **Ver logs:**
   ```bash
   firebase functions:log
   ```

## 🔧 Si hay problemas

### Error: "Functions requires Node.js 18"
Ya está actualizado a Node.js 20 en `package.json`

### Error: "Permission denied"
Asegúrate de tener permisos de administrador en Firebase

### Las notificaciones no llegan
1. Verifica que los usuarios hayan dado permisos de notificaciones
2. Verifica que los tokens FCM estén en `fcm_tokens` en Firestore
3. Revisa los logs de Cloud Functions

## 📚 Documentación Completa

Para más detalles, ver:
- `DESPLIEGUE_CLOUD_FUNCTIONS.md` - Guía completa
- `CLOUD_FUNCTIONS_SETUP.md` - Configuración inicial
