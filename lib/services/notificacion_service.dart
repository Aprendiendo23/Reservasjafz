import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'fcm_service.dart';

class NotificacionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FCMService _fcmService = FCMService();

  CollectionReference get notificacionesCollection =>
      _firestore.collection('notificaciones');

  /// Crear una notificación para un usuario específico
  Future<void> crearNotificacion({
    required String usuarioID,
    required String titulo,
    required String mensaje,
    required String tipo,
    Map<String, dynamic>? datosAdicionales,
    bool leida = false,
  }) async {
    try {
      await notificacionesCollection.add({
        'usuarioID': usuarioID,
        'titulo': titulo,
        'mensaje': mensaje,
        'tipo': tipo,
        'leida': leida,
        'creado': FieldValue.serverTimestamp(),
        if (datosAdicionales != null) ...datosAdicionales,
      });
      print('✅ Notificación creada para usuario: $usuarioID');
    } catch (e) {
      print('❌ Error al crear notificación: $e');
      rethrow;
    }
  }

  /// Crear notificaciones para todos los usuarios cuando se crea una reserva
  Future<void> notificarNuevaReserva({
    required String docenteNombre,
    required String docenteUsuarioID, // ID del docente que creó la reserva
    required String dia,
    required String hora,
    required String recursoNombre,
    required String grado,
    DateTime? fechaUso,
    String? asignatura,
    String? reservaID,
  }) async {
    try {
      // Obtener todos los usuarios
      final usuariosSnapshot = await _firestore.collection('usuarios').get();
      
      if (usuariosSnapshot.docs.isEmpty) {
        print('⚠️ No hay usuarios para notificar');
        return;
      }

      // Formatear la fecha si está disponible
      String fechaFormateada = '';
      if (fechaUso != null) {
        fechaFormateada = DateFormat('dd-MM-yyyy').format(fechaUso);
      }

      // Determinar si es un bloque o una hora individual
      String horaOBloque = hora;
      if (hora.startsWith('Bloque')) {
        horaOBloque = hora; // Ya incluye "Bloque X (Xª+Xª)"
      }

      // Crear el mensaje de la notificación push
      // Formato: "El docente [nombre] ha reservado el recurso [recurso], la hora [hora], el día [día]"
      String mensaje = 'El docente $docenteNombre ha reservado el recurso $recursoNombre, la hora $horaOBloque, el día $dia';
      if (fechaFormateada.isNotEmpty) {
        mensaje += ' ($fechaFormateada)';
      }

      // NOTIFICACIONES IN-APP DESHABILITADAS
      // Las notificaciones dentro de la aplicación han sido deshabilitadas
      // Solo se envían push notifications (si están configuradas)

      // Enviar notificaciones push (opcional, solo si Cloud Functions está configurado)
      await _enviarPushNotifications(
        titulo: 'Nueva Reserva Creada',
        mensaje: mensaje,
        docenteUsuarioID: docenteUsuarioID,
        reservaID: reservaID,
      );
    } catch (e) {
      print('❌ Error al notificar nueva reserva: $e');
      // No lanzar excepción para no interrumpir la creación de la reserva
    }
  }

  /// Enviar notificaciones push a todos los usuarios
  Future<void> _enviarPushNotifications({
    required String titulo,
    required String mensaje,
    required String docenteUsuarioID,
    String? reservaID,
  }) async {
    try {
      // Obtener todos los tokens FCM (excepto el docente que creó la reserva)
      final tokens = await _fcmService.obtenerTokensUsuarios(
        excluirUsuarioID: docenteUsuarioID,
      );

      if (tokens.isEmpty) {
        print('⚠️ No hay tokens FCM disponibles para enviar push notifications');
        return;
      }

      // Crear un documento en Firestore que Cloud Functions puede procesar
      // Esto permite que Cloud Functions envíe las notificaciones push
      await _firestore.collection('push_notifications_queue').add({
        'titulo': titulo,
        'mensaje': mensaje,
        'tokens': tokens,
        'tipo': 'nueva_reserva',
        'reservaID': reservaID,
        'creado': FieldValue.serverTimestamp(),
        'procesado': false,
      });

      print('✅ Push notification encolada para ${tokens.length} dispositivos');
      print('   Nota: Se requiere Cloud Functions para procesar y enviar las notificaciones push');
    } catch (e) {
      print('❌ Error al encolar push notifications: $e');
      // No lanzar excepción para no interrumpir el proceso
    }
  }

  /// Obtener notificaciones de un usuario
  Stream<QuerySnapshot> getNotificacionesUsuario(String usuarioID) {
    return notificacionesCollection
        .where('usuarioID', isEqualTo: usuarioID)
        .orderBy('creado', descending: true)
        .snapshots();
  }

  /// Obtener notificaciones no leídas de un usuario
  Stream<QuerySnapshot> getNotificacionesNoLeidas(String usuarioID) {
    return notificacionesCollection
        .where('usuarioID', isEqualTo: usuarioID)
        .where('leida', isEqualTo: false)
        .orderBy('creado', descending: true)
        .snapshots();
  }

  /// Marcar notificación como leída
  Future<void> marcarComoLeida(String notificacionID) async {
    try {
      await notificacionesCollection.doc(notificacionID).update({
        'leida': true,
        'fechaLeida': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error al marcar notificación como leída: $e');
      rethrow;
    }
  }

  /// Marcar todas las notificaciones de un usuario como leídas
  Future<void> marcarTodasComoLeidas(String usuarioID) async {
    try {
      final notificaciones = await notificacionesCollection
          .where('usuarioID', isEqualTo: usuarioID)
          .where('leida', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in notificaciones.docs) {
        batch.update(doc.reference, {
          'leida': true,
          'fechaLeida': FieldValue.serverTimestamp(),
        });
      }

      if (notificaciones.docs.isNotEmpty) {
        await batch.commit();
        print('✅ ${notificaciones.docs.length} notificaciones marcadas como leídas');
      }
    } catch (e) {
      print('❌ Error al marcar todas las notificaciones como leídas: $e');
      rethrow;
    }
  }

  /// Eliminar notificación
  Future<void> eliminarNotificacion(String notificacionID) async {
    try {
      await notificacionesCollection.doc(notificacionID).delete();
    } catch (e) {
      print('❌ Error al eliminar notificación: $e');
      rethrow;
    }
  }

  /// Contar notificaciones no leídas de un usuario
  Future<int> contarNotificacionesNoLeidas(String usuarioID) async {
    try {
      final snapshot = await notificacionesCollection
          .where('usuarioID', isEqualTo: usuarioID)
          .where('leida', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error al contar notificaciones no leídas: $e');
      return 0;
    }
  }
}
