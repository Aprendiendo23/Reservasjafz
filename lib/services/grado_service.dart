import 'package:cloud_firestore/cloud_firestore.dart';

class GradoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get gradosCollection =>
      _firestore.collection('grados');

  // Obtener grados activos
  Stream<QuerySnapshot> getGradosActivos() {
    try {
      // Simplificar: solo filtrar por activo, ordenar en memoria si es necesario
      // Esto evita problemas con índices compuestos
      return gradosCollection
          .where('activo', isEqualTo: true)
          .snapshots();
    } catch (e) {
      print('Error en getGradosActivos: $e');
      // Si hay error, retornar un stream vacío
      return gradosCollection.where('activo', isEqualTo: 'ERROR_TEMP').limit(0).snapshots();
    }
  }

  // Obtener todos los grados (activos e inactivos)
  Stream<QuerySnapshot> getTodosLosGrados() {
    // Devolvemos el stream sin orden específico y ordenamos en memoria
    // según el campo "orden" para poder reordenar desde la interfaz.
    return gradosCollection.snapshots();
  }

  // Crear grado
  Future<void> crearGrado(String nombre) async {
    // Asignar un orden inicial al final de la lista actual
    final snapshot = await gradosCollection.get();
    final nuevoOrden = snapshot.docs.length;

    await gradosCollection.add({
      'nombre': nombre.trim(),
      'activo': true,
      'creado': FieldValue.serverTimestamp(),
      'orden': nuevoOrden,
    });
  }

  // Actualizar grado
  Future<void> actualizarGrado(String id, String nombre) async {
    await gradosCollection.doc(id).update({
      'nombre': nombre.trim(),
      'actualizado': FieldValue.serverTimestamp(),
    });
  }

  // Desactivar grado
  Future<void> desactivarGrado(String id) async {
    await gradosCollection.doc(id).update({
      'activo': false,
      'actualizado': FieldValue.serverTimestamp(),
    });
  }

  // Activar grado
  Future<void> activarGrado(String id) async {
    await gradosCollection.doc(id).update({
      'activo': true,
      'actualizado': FieldValue.serverTimestamp(),
    });
  }

  // Eliminar grado
  Future<void> eliminarGrado(String id) async {
    await gradosCollection.doc(id).delete();
  }

  /// Actualizar el campo "orden" de varios grados en una sola operación.
  /// [ordenes] es un mapa: idGrado -> índice (0,1,2,...).
  Future<void> actualizarOrdenes(Map<String, int> ordenes) async {
    final batch = _firestore.batch();

    ordenes.forEach((id, orden) {
      final ref = gradosCollection.doc(id);
      batch.update(ref, {'orden': orden});
    });

    await batch.commit();
  }
}

