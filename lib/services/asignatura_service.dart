import 'package:cloud_firestore/cloud_firestore.dart';

class AsignaturaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get asignaturasCollection =>
      _firestore.collection('asignaturas');

  // Obtener asignaturas activas
  Stream<QuerySnapshot> getAsignaturasActivas() {
    try {
      // Filtrar por activo sin orderBy para evitar necesidad de índice compuesto
      // El ordenamiento se hará en memoria
      return asignaturasCollection
          .where('activo', isEqualTo: true)
          .snapshots();
    } catch (e) {
      print('Error en getAsignaturasActivas: $e');
      // Si hay error, retornar un stream vacío
      return asignaturasCollection.where('activo', isEqualTo: 'ERROR_TEMP').limit(0).snapshots();
    }
  }

  // Obtener todas las asignaturas (activas e inactivas)
  Stream<QuerySnapshot> getTodasLasAsignaturas() {
    // No usamos orderBy en Firestore para poder controlar el orden desde la app
    // utilizando el campo "orden" y ordenando en memoria.
    return asignaturasCollection.snapshots();
  }

  // Crear asignatura
  Future<void> crearAsignatura(String nombre) async {
    // Asignar un orden inicial al final de la lista actual
    final snapshot = await asignaturasCollection.get();
    final nuevoOrden = snapshot.docs.length;

    await asignaturasCollection.add({
      'nombre': nombre.trim(),
      'activo': true,
      'creado': FieldValue.serverTimestamp(),
      'orden': nuevoOrden,
    });
  }

  // Actualizar asignatura
  Future<void> actualizarAsignatura(String id, String nombre) async {
    await asignaturasCollection.doc(id).update({
      'nombre': nombre.trim(),
      'actualizado': FieldValue.serverTimestamp(),
    });
  }

  // Desactivar asignatura
  Future<void> desactivarAsignatura(String id) async {
    await asignaturasCollection.doc(id).update({
      'activo': false,
      'actualizado': FieldValue.serverTimestamp(),
    });
  }

  // Activar asignatura
  Future<void> activarAsignatura(String id) async {
    await asignaturasCollection.doc(id).update({
      'activo': true,
      'actualizado': FieldValue.serverTimestamp(),
    });
  }

  // Eliminar asignatura
  Future<void> eliminarAsignatura(String id) async {
    await asignaturasCollection.doc(id).delete();
  }

  /// Actualizar el campo "orden" de varias asignaturas en una sola operación.
  /// [ordenes] es un mapa: idAsignatura -> índice (0,1,2,...).
  Future<void> actualizarOrdenes(Map<String, int> ordenes) async {
    final batch = _firestore.batch();

    ordenes.forEach((id, orden) {
      final ref = asignaturasCollection.doc(id);
      batch.update(ref, {'orden': orden});
    });

    await batch.commit();
  }

  // Crear asignaturas por defecto
  Future<Map<String, int>> crearAsignaturasPorDefecto() async {
    // Lista de asignaturas por defecto (mismo orden que en crear_reserva.dart)
    final asignaturasDefault = [
      'Lengua y Literatura',
      'Matemática',
      'Inglés',
      'Ciencias Sociales',
      'Ciencias Naturales',
      'Física',
      'Química',
      'Biología',
      'Creciendo en Valores',
      'AEP',
      'TAC',
      'Educación Física',
    ];

    // Obtener asignaturas existentes
    final asignaturasExistentes = await asignaturasCollection.get();
    final nombresExistentes = asignaturasExistentes.docs
        .map((doc) => (doc.data() as Map<String, dynamic>)['nombre'] as String?)
        .where((nombre) => nombre != null)
        .toSet();

    int creadas = 0;
    int yaExistentes = 0;

    for (final nombre in asignaturasDefault) {
      if (nombresExistentes.contains(nombre)) {
        yaExistentes++;
      } else {
        await asignaturasCollection.add({
          'nombre': nombre.trim(),
          'activo': true,
          'creado': FieldValue.serverTimestamp(),
        });
        creadas++;
      }
    }

    return {
      'creadas': creadas,
      'yaExistentes': yaExistentes,
    };
  }
}
