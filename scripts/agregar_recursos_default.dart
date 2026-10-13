import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../lib/firebase_options.dart';

/// Script para agregar recursos por defecto a Firestore
/// Ejecutar con: dart run scripts/agregar_recursos_default.dart
Future<void> main() async {
  try {
    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final firestore = FirebaseFirestore.instance;
    final recursosCollection = firestore.collection('recursos');

    print('🚀 Iniciando creación de recursos por defecto...\n');

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
        'nombre': 'Proyector',
        'descripcion': 'Proyector para presentaciones',
        'tipo': 'proyector',
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
    ];

    // Verificar si los recursos ya existen
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
        print('⏭️  "$nombre" ya existe, omitiendo...');
        yaExistentes++;
      } else {
        await recursosCollection.add(recurso);
        print('✅ Creado: $nombre');
        creados++;
      }
    }

    print('\n📊 Resumen:');
    print('   - Recursos creados: $creados');
    print('   - Recursos ya existentes: $yaExistentes');
    print('\n🎉 ¡Proceso completado!');
  } catch (e) {
    print('❌ Error: $e');
    rethrow;
  }
}

