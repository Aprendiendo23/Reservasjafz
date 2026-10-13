/**
 * Script para crear las colecciones y documentos de ejemplo en Firestore
 * 
 * USO:
 * 1. Instala Firebase Admin SDK: npm install firebase-admin
 * 2. Configura las credenciales de servicio en un archivo JSON
 * 3. Ejecuta: node scripts/crear_colecciones.js
 * 
 * O usa Firebase Console manualmente siguiendo CONFIGURAR_FIREBASE_COMPLETO.md
 */

const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json'); // Descarga desde Firebase Console

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function crearColecciones() {
  try {
    console.log('🚀 Iniciando creación de colecciones...\n');

    // 1. Crear usuario administrador de ejemplo
    console.log('📝 Creando usuario administrador...');
    const adminUID = 'ADMIN_UID_AQUI'; // Reemplaza con un UID real
    await db.collection('usuarios').doc(adminUID).set({
      nombre: 'Administrador',
      email: 'admin@ejemplo.com',
      rol: 'admin',
      foto: '',
      creado: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log('✅ Usuario admin creado\n');

    // 2. Crear recursos de ejemplo
    console.log('📝 Creando recursos de ejemplo...');
    const recursos = [
      {
        nombre: 'Proyector 1',
        descripcion: 'Proyector Epson de alta definición',
        tipo: 'proyector',
        estado: 'activo',
        disponible: true,
        creado: admin.firestore.FieldValue.serverTimestamp()
      },
      {
        nombre: 'Sala de Reuniones A',
        descripcion: 'Sala con capacidad para 20 personas',
        tipo: 'sala',
        estado: 'activo',
        disponible: true,
        creado: admin.firestore.FieldValue.serverTimestamp()
      },
      {
        nombre: 'Laptop 1',
        descripcion: 'Laptop Dell para presentaciones',
        tipo: 'equipo',
        estado: 'activo',
        disponible: true,
        creado: admin.firestore.FieldValue.serverTimestamp()
      }
    ];

    for (const recurso of recursos) {
      await db.collection('recursos').add(recurso);
    }
    console.log('✅ Recursos creados\n');

    console.log('🎉 ¡Colecciones creadas exitosamente!');
    console.log('\n⚠️  IMPORTANTE:');
    console.log('1. Reemplaza ADMIN_UID_AQUI con un UID real de Authentication');
    console.log('2. O crea el usuario admin manualmente desde Firebase Console');
    console.log('3. Configura las reglas y índices siguiendo CONFIGURAR_FIREBASE_COMPLETO.md');

  } catch (error) {
    console.error('❌ Error:', error);
  }
}

// Ejecutar solo si se llama directamente
if (require.main === module) {
  crearColecciones().then(() => process.exit(0));
}

module.exports = { crearColecciones };

