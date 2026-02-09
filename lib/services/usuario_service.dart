import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsuarioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get usuariosCollection =>
      _firestore.collection('usuarios');

  // Obtener usuario actual
  Future<DocumentSnapshot?> getUsuarioActual() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    return await usuariosCollection.doc(user.uid).get();
  }

  // Obtener stream del usuario actual (para actualizaciones en tiempo real)
  Stream<DocumentSnapshot> getUsuarioActualStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream<DocumentSnapshot>.empty();
    }
    return usuariosCollection.doc(user.uid).snapshots();
  }

  // Obtener todos los usuarios
  Stream<QuerySnapshot> getUsuarios() {
    return usuariosCollection.snapshots();
  }

  // Obtener usuarios por rol
  Stream<QuerySnapshot> getUsuariosPorRol(String rol) {
    return usuariosCollection.where('rol', isEqualTo: rol).snapshots();
  }

  // Crear o actualizar usuario
  Future<void> guardarUsuario(String userId, Map<String, dynamic> data) async {
    data['creado'] = FieldValue.serverTimestamp();
    await usuariosCollection.doc(userId).set(data, SetOptions(merge: true));
  }

  // Crear o actualizar usuario (método alternativo con parámetros)
  Future<void> crearOActualizarUsuario({
    required String userId,
    required String nombre,
    required String email,
    required String rol,
    String? foto,
  }) async {
    await usuariosCollection.doc(userId).set({
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'foto': foto ?? '',
      'creado': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Obtener usuario por ID
  Future<DocumentSnapshot> getUsuario(String userId) async {
    return await usuariosCollection.doc(userId).get();
  }

  // Verificar si un usuario es admin
  Future<bool> esAdmin(String userId) async {
    final doc = await usuariosCollection.doc(userId).get();
    if (!doc.exists) return false;
    final data = doc.data() as Map<String, dynamic>?;
    return data?['rol'] == 'admin';
  }

  // Obtener rol del usuario actual
  Future<String?> getRolUsuarioActual() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await usuariosCollection.doc(user.uid).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>?;
    return data?['rol'] as String?;
  }

  // Actualizar nombre del usuario actual
  Future<void> actualizarNombre(String nombre) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Usuario no autenticado';

    if (nombre.trim().isEmpty) {
      throw 'El nombre no puede estar vacío';
    }

    // Usar set con merge: true en lugar de update para evitar errores
    // si el documento no existe y para prevenir duplicaciones
    await usuariosCollection.doc(user.uid).set({
      'nombre': nombre.trim(),
    }, SetOptions(merge: true));
  }

  // Actualizar nombre de cualquier usuario (para admin)
  Future<void> actualizarNombreUsuario(String usuarioId, String nombre) async {
    if (nombre.trim().isEmpty) {
      throw 'El nombre no puede estar vacío';
    }

    // Usar set con merge: true en lugar de update para evitar errores
    // si el documento no existe y para prevenir duplicaciones
    await usuariosCollection.doc(usuarioId).set({
      'nombre': nombre.trim(),
    }, SetOptions(merge: true));
  }
}
