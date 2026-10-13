const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Inicializar Firebase Admin
admin.initializeApp();

/**
 * Función que se ejecuta cuando se crea un documento en push_notifications_queue
 * Envía notificaciones push a todos los tokens especificados
 */
exports.sendPushNotifications = functions.firestore
    .document("push_notifications_queue/{queueId}")
    .onCreate(async (snap, context) => {
      const data = snap.data();

      // Verificar que no esté procesado
      if (data.procesado === true) {
        console.log("Documento ya procesado, ignorando...");
        return null;
      }

      const {titulo, mensaje, tokens, tipo, reservaID} = data;

      // Validar datos
      if (!titulo || !mensaje) {
        console.error("Faltan título o mensaje");
        return snap.ref.update({
          procesado: true,
          error: "Faltan título o mensaje",
          procesadoEn: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
        console.log("No hay tokens para enviar");
        return snap.ref.update({
          procesado: true,
          error: "No hay tokens disponibles",
          procesadoEn: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      console.log(`📤 Enviando notificaciones a ${tokens.length} dispositivos`);
      console.log(`   Título: ${titulo}`);
      console.log(`   Mensaje: ${mensaje.substring(0, 50)}...`);

      // Preparar el mensaje de notificación
      const message = {
        notification: {
          title: titulo,
          body: mensaje,
        },
        data: {
          tipo: tipo || "nueva_reserva",
          reservaID: reservaID || "",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        // Enviar a múltiples tokens usando sendEachForMulticast
        tokens: tokens,
      };

      try {
      // Enviar notificaciones a múltiples dispositivos
        const response = await admin.messaging().sendEachForMulticast(message);

        console.log(`✅ ${response.successCount} notificaciones enviadas exitosamente`);
        console.log(`❌ ${response.failureCount} notificaciones fallaron`);

        // Procesar tokens fallidos
        const failedTokens = [];
        if (response.failureCount > 0) {
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              failedTokens.push(tokens[idx]);
              const errorMsg = resp.error?.message || "Error desconocido";
              const tokenPreview = tokens[idx].substring(0, 20);
              console.log(`   Token fallido: ${tokenPreview}... - ${errorMsg}`);
            }
          });
        }

        // Marcar como procesado
        await snap.ref.update({
          procesado: true,
          procesadoEn: admin.firestore.FieldValue.serverTimestamp(),
          exitosos: response.successCount,
          fallidos: response.failureCount,
          tokensFallidos: failedTokens.length > 0 ? failedTokens : admin.firestore.FieldValue.delete(),
        });

        // Si hay tokens inválidos, eliminarlos de la base de datos
        if (failedTokens.length > 0) {
          console.log(`🗑️ Eliminando ${failedTokens.length} tokens inválidos de Firestore`);
          const db = admin.firestore();
          const batch = db.batch();

          for (const token of failedTokens) {
          // Buscar y eliminar tokens inválidos
            const tokensSnapshot = await db.collection("fcm_tokens")
                .where("token", "==", token)
                .get();

            tokensSnapshot.forEach((doc) => {
              batch.delete(doc.ref);
            });
          }

          await batch.commit();
        }

        return null;
      } catch (error) {
        console.error("❌ Error al enviar notificaciones:", error);
        await snap.ref.update({
          procesado: true,
          error: error.message,
          procesadoEn: admin.firestore.FieldValue.serverTimestamp(),
        });
        return null;
      }
    });

/**
 * Función HTTP alternativa para enviar notificaciones manualmente
 * Útil para pruebas o envíos manuales
 */
exports.sendPushNotificationManual = functions.https.onCall(async (data, context) => {
  // Verificar autenticación
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "Usuario no autenticado",
    );
  }

  const {titulo, mensaje, tokens} = data;

  if (!titulo || !mensaje || !tokens || !Array.isArray(tokens)) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Faltan parámetros requeridos: titulo, mensaje, tokens",
    );
  }

  const message = {
    notification: {
      title: titulo,
      body: mensaje,
    },
    tokens: tokens,
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    return {
      success: true,
      sent: response.successCount,
      failed: response.failureCount,
    };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});
