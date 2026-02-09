import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener referencia a la colección de recursos
  CollectionReference get recursosCollection =>
      _firestore.collection('recursos');

  // Obtener referencia a la colección de reservas
  CollectionReference get reservasCollection =>
      _firestore.collection('reservas');

  // Obtener referencia a la colección de usuarios
  CollectionReference get usuariosCollection =>
      _firestore.collection('usuarios');

  // Obtener todos los recursos
  Stream<QuerySnapshot> getRecursos() {
    return recursosCollection.snapshots();
  }

  // Obtener un recurso por ID
  Future<DocumentSnapshot> getRecurso(String id) {
    return recursosCollection.doc(id).get();
  }

  // Obtener reservas de un usuario
  Stream<QuerySnapshot> getReservasUsuario(String userId) {
    return reservasCollection
        .where('usuarioID', isEqualTo: userId)
        .orderBy('fechaInicio', descending: true)
        .snapshots();
  }

  // Obtener todas las reservas
  Stream<QuerySnapshot> getReservas() {
    return reservasCollection
        .orderBy('fechaInicio', descending: true)
        .snapshots();
  }

  // Crear una reserva
  Future<void> crearReserva(Map<String, dynamic> reservaData) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'Usuario no autenticado';
    }

    reservaData['usuarioID'] = user.uid;
    reservaData['usuarioEmail'] = user.email ?? 'N/A';
    reservaData['fechaCreacion'] = FieldValue.serverTimestamp();
    reservaData['estado'] = reservaData['estado'] ?? 'activa';

    await reservasCollection.add(reservaData);
  }

  // Actualizar una reserva
  Future<void> actualizarReserva(String id, Map<String, dynamic> data) async {
    await reservasCollection.doc(id).update(data);
  }

  // Eliminar una reserva
  Future<void> eliminarReserva(String id) async {
    await reservasCollection.doc(id).delete();
  }

  // Crear o actualizar un recurso
  Future<void> guardarRecurso(String? id, Map<String, dynamic> data) async {
    if (id == null) {
      await recursosCollection.add(data);
    } else {
      await recursosCollection.doc(id).update(data);
    }
  }

  // Eliminar un recurso
  Future<void> eliminarRecurso(String id) async {
    await recursosCollection.doc(id).delete();
  }

  // Verificar disponibilidad de un recurso en un rango de fechas
  Future<bool> verificarDisponibilidad(
    String recursoId,
    DateTime fechaInicio,
    DateTime fechaFin,
    String? reservaIdExcluir,
  ) async {
    final query = reservasCollection
        .where('recursoID', isEqualTo: recursoId)
        .where('estado', isEqualTo: 'activa');

    final snapshot = await query.get();

    for (var doc in snapshot.docs) {
      if (reservaIdExcluir != null && doc.id == reservaIdExcluir) {
        continue;
      }

      final reserva = doc.data() as Map<String, dynamic>;
      final inicioReserva = (reserva['fechaInicio'] as Timestamp).toDate();
      final finReserva = (reserva['fechaFin'] as Timestamp).toDate();

      // Verificar solapamiento
      if (fechaInicio.isBefore(finReserva) && fechaFin.isAfter(inicioReserva)) {
        return false; // No disponible
      }
    }

    return true; // Disponible
  }
}

