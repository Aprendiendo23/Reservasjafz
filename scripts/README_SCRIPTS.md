# 📜 Scripts de Configuración

Este directorio contiene scripts auxiliares para configurar Firebase.

## ⚠️ Nota Importante

**La forma más fácil y recomendada es usar Firebase Console manualmente** siguiendo las instrucciones en `CONFIGURAR_FIREBASE_COMPLETO.md`.

Los scripts aquí son opcionales y requieren configuración adicional.

---

## 📋 Scripts Disponibles

### `crear_colecciones.js`

Script de Node.js para crear colecciones y documentos de ejemplo automáticamente.

**Requisitos:**
- Node.js instalado
- Firebase Admin SDK
- Credenciales de servicio de Firebase

**Uso:**
```bash
# 1. Instalar dependencias
npm install firebase-admin

# 2. Descargar credenciales de servicio desde Firebase Console:
#    Project Settings → Service Accounts → Generate New Private Key

# 3. Guardar el archivo JSON como serviceAccountKey.json en la raíz del proyecto

# 4. Editar el script y reemplazar ADMIN_UID_AQUI con un UID real

# 5. Ejecutar
node scripts/crear_colecciones.js
```

---

## 🎯 Método Recomendado

**Usa Firebase Console** siguiendo `CONFIGURAR_FIREBASE_COMPLETO.md` - es más simple y no requiere configuración adicional.

