import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Handler para notificaciones cuando la app está en primer plano
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📬 Notificación recibida en background: ${message.messageId}');
  print('   Título: ${message.notification?.title}');
  print('   Cuerpo: ${message.notification?.body}');
}

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Inicializar FCM y solicitar permisos
  Future<void> initialize() async {
    try {
      // Solicitar permisos de notificaciones
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('🔔 Permisos de notificación: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Permisos de notificación concedidos');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ Permisos de notificación provisionales');
      } else {
        print('❌ Permisos de notificación denegados');
        return;
      }

      // Configurar handler para notificaciones en background
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Obtener token FCM
      String? token = await _messaging.getToken();
      if (token != null) {
        print('📱 Token FCM obtenido: ${token.substring(0, 20)}...');
        await _guardarToken(token);
      }

      // Escuchar cambios en el token
      _messaging.onTokenRefresh.listen((newToken) {
        print('🔄 Token FCM actualizado: ${newToken.substring(0, 20)}...');
        _guardarToken(newToken);
      });

      // Escuchar notificaciones cuando la app está en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📬 Notificación recibida en primer plano:');
        print('   Título: ${message.notification?.title}');
        print('   Cuerpo: ${message.notification?.body}');
        print('   Datos: ${message.data}');
      });

      // Manejar notificaciones cuando el usuario toca la notificación
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('👆 Usuario tocó la notificación:');
        print('   Título: ${message.notification?.title}');
        print('   Datos: ${message.data}');
      });

      // Verificar si la app se abrió desde una notificación
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        print('🚀 App abierta desde notificación:');
        print('   Título: ${initialMessage.notification?.title}');
        print('   Datos: ${initialMessage.data}');
      }
    } catch (e) {
      print('❌ Error al inicializar FCM: $e');
    }
  }

  /// Guardar token FCM del usuario en Firestore
  Future<void> _guardarToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('⚠️ No hay usuario autenticado, no se guardará el token');
      return;
    }

    try {
      // Guardar token en la colección de usuarios
      await _firestore.collection('usuarios').doc(user.uid).update({
        'fcmToken': token,
        'fcmTokenActualizado': FieldValue.serverTimestamp(),
      });

      // También guardar en una colección separada de tokens para facilitar consultas
      await _firestore.collection('fcm_tokens').doc(user.uid).set({
        'usuarioID': user.uid,
        'token': token,
        'actualizado': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Token FCM guardado para usuario: ${user.uid}');
    } catch (e) {
      print('❌ Error al guardar token FCM: $e');
    }
  }

  /// Obtener token FCM actual
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('❌ Error al obtener token FCM: $e');
      return null;
    }
  }

  /// Eliminar token cuando el usuario cierra sesión
  Future<void> eliminarToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Eliminar token de la colección de usuarios
      await _firestore.collection('usuarios').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
      });

      // Eliminar de la colección de tokens
      await _firestore.collection('fcm_tokens').doc(user.uid).delete();

      // Eliminar token del dispositivo
      await _messaging.deleteToken();

      print('✅ Token FCM eliminado');
    } catch (e) {
      print('❌ Error al eliminar token FCM: $e');
    }
  }

  /// Obtener todos los tokens FCM de usuarios (excepto el usuario actual)
  Future<List<String>> obtenerTokensUsuarios({String? excluirUsuarioID}) async {
    try {
      QuerySnapshot snapshot;
      
      if (excluirUsuarioID != null) {
        snapshot = await _firestore
            .collection('fcm_tokens')
            .where('usuarioID', isNotEqualTo: excluirUsuarioID)
            .get();
      } else {
        snapshot = await _firestore.collection('fcm_tokens').get();
      }

      List<String> tokens = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final token = data['token'] as String?;
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }

      print('📱 Tokens FCM obtenidos: ${tokens.length}');
      return tokens;
    } catch (e) {
      print('❌ Error al obtener tokens FCM: $e');
      return [];
    }
  }
}
