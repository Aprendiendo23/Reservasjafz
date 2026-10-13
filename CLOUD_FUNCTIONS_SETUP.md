# 🔔 Configuración de Cloud Functions para Notificaciones Push

## 📋 Resumen

Para que las notificaciones push funcionen completamente, necesitas configurar **Firebase Cloud Functions** que procesen la cola de notificaciones y las envíen a los dispositivos.

## 🚀 Pasos para Configurar Cloud Functions

### 1. Instalar Firebase CLI

```bash
npm install -g firebase-tools
```

### 2. Inicializar Cloud Functions en tu proyecto

```bash
cd /ruta/a/tu/proyecto
firebase init functions
```

Selecciona:
- ✅ JavaScript o TypeScript
- ✅ Instalar dependencias

### 3. Crear la función para enviar notificaciones push

Crea o edita el archivo `functions/index.js`:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendPushNotifications = functions.firestore
  .document('push_notifications_queue/{queueId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    
    // Verificar que no esté procesado
    if (data.procesado === true) {
      return null;
    }

    const { titulo, mensaje, tokens, tipo, reservaID } = data;
    
    if (!tokens || tokens.length === 0) {
      console.log('No hay tokens para enviar');
      return snap.ref.update({ procesado: true, error: 'No hay tokens' });
    }

    // Preparar el mensaje de notificación
    const message = {
      notification: {
        title: titulo,
        body: mensaje,
      },
      data: {
        tipo: tipo || 'nueva_reserva',
        reservaID: reservaID || '',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      tokens: tokens, // Array de tokens FCM
    };

    try {
      // Enviar notificaciones a múltiples dispositivos
      const response = await admin.messaging().sendEachForMulticast(message);
      
      console.log(`✅ ${response.successCount} notificaciones enviadas exitosamente`);
      console.log(`❌ ${response.failureCount} notificaciones fallaron`);

      // Marcar como procesado
      await snap.ref.update({
        procesado: true,
        enviado: FieldValue.serverTimestamp(),
        exitosos: response.successCount,
        fallidos: response.failureCount,
      });

      // Eliminar tokens inválidos
      if (response.failureCount > 0) {
        const failedTokens = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            failedTokens.push(tokens[idx]);
          }
        });
        console.log('Tokens inválidos:', failedTokens);
      }

      return null;
    } catch (error) {
      console.error('Error al enviar notificaciones:', error);
      await snap.ref.update({
        procesado: true,
        error: error.message,
      });
      return null;
    }
  });
```

### 4. Instalar dependencias

```bash
cd functions
npm install firebase-functions firebase-admin
```

### 5. Desplegar la función

```bash
firebase deploy --only functions
```

## 📝 Estructura de Datos

### Colección: `push_notifications_queue`

```json
{
  "titulo": "Nueva Reserva Creada",
  "mensaje": "El docente Juan Pérez ha creado una nueva reserva...",
  "tokens": ["token1", "token2", "token3"],
  "tipo": "nueva_reserva",
  "reservaID": "abc123",
  "creado": "2024-01-01T00:00:00Z",
  "procesado": false
}
```

## ✅ Verificación

1. Crea una reserva desde la app
2. Verifica en Firebase Console > Functions que la función se ejecutó
3. Verifica en Firebase Console > Firestore que el documento se marcó como `procesado: true`
4. Los usuarios deberían recibir la notificación push en sus dispositivos

## 🔧 Alternativa: Usar HTTP Function

Si prefieres llamar la función manualmente, puedes crear una HTTP function:

```javascript
exports.sendPushNotification = functions.https.onCall(async (data, context) => {
  // Verificar autenticación
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Usuario no autenticado');
  }

  const { titulo, mensaje, tokens } = data;
  
  const message = {
    notification: {
      title: titulo,
      body: mensaje,
    },
    tokens: tokens,
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    return { success: true, sent: response.successCount };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});
```

## 📚 Recursos

- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Send messages to multiple devices](https://firebase.google.com/docs/cloud-messaging/send-message#send_to_multiple_devices)
