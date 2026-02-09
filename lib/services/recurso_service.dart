import 'package:cloud_firestore/cloud_firestore.dart';

class RecursoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get recursosCollection =>
      _firestore.collection('recursos');

  // Obtener todos los recursos
  Stream<QuerySnapshot> getRecursos() {
    return recursosCollection.snapshots();
  }

  // Obtener recursos activos
  Stream<QuerySnapshot> getRecursosActivos() {
    try {
      return recursosCollection.where('estado', isEqualTo: 'activo').snapshots();
    } catch (e) {
      print('Error en getRecursosActivos: $e');
      // Si hay error, retornar un stream vacío
      return recursosCollection.where('estado', isEqualTo: 'ERROR_TEMP').limit(0).snapshots();
    }
  }

  // Obtener un recurso por ID
  Future<DocumentSnapshot> getRecurso(String id) {
    return recursosCollection.doc(id).get();
  }

  // Crear recurso
  Future<void> crearRecurso(Map<String, dynamic> data) async {
    await recursosCollection.add(data);
  }

  // Actualizar recurso
  Future<void> actualizarRecurso(String id, Map<String, dynamic> data) async {
    await recursosCollection.doc(id).update(data);
  }

  // Eliminar recurso
  Future<void> eliminarRecurso(String id) async {
    await recursosCollection.doc(id).delete();
  }

  // Contar recursos activos
  Future<int> contarRecursosActivos() async {
    final snapshot = await recursosCollection
        .where('estado', isEqualTo: 'activo')
        .get();
    return snapshot.docs.length;
  }

  // Crear recursos por defecto
  Future<Map<String, int>> crearRecursosPorDefecto() async {
    // Lista de recursos por defecto
    final recursosDefault = [
      {
        'nombre': 'Laptop',
        'descripcion': 'Laptop para uso educativo',
        'tipo': 'laptop',
        'estado': 'activo',
        'creado': FieldValue.serverTimestamp(),
      },
      {
        'nombre': 'Laptop y Proyector',
        'descripcion': 'Combinación de laptop y proyector para presentaciones',
        'tipo': 'combinado',
        'estado': 'activo',
        'creado': FieldValue.serverTimestamp(),
      },
      {
        'nombre': 'Tablet, laptop y Proyector',
        'descripcion': 'Combinación completa de tablet, laptop y proyector',
        'tipo': 'combinado',
        'estado': 'activo',
        'creado': FieldValue.serverTimestamp(),
      },
      {
        'nombre': 'Tablet',
        'descripcion': 'Tablet para uso educativo',
        'tipo': 'tablet',
        'estado': 'activo',
        'creado': FieldValue.serverTimestamp(),
      },
      {
        'nombre': 'Proyector',
        'descripcion': 'Proyector para presentaciones',
        'tipo': 'proyector',
        'estado': 'activo',
        'creado': FieldValue.serverTimestamp(),
      },
    ];

    // Obtener recursos existentes
    final recursosExistentes = await recursosCollection.get();
    final nombresExistentes = recursosExistentes.docs
        .map((doc) => (doc.data() as Map<String, dynamic>)['nombre'] as String?)
        .where((nombre) => nombre != null)
        .toSet();

    int creados = 0;
    int yaExistentes = 0;

    for (final recurso in recursosDefault) {
      final nombre = recurso['nombre'] as String;
      
      if (nombresExistentes.contains(nombre)) {
        yaExistentes++;
      } else {
        await recursosCollection.add(recurso);
        creados++;
      }
    }

    return {
      'creados': creados,
      'yaExistentes': yaExistentes,
    };
  }
}
