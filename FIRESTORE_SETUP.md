# Configuración de Firestore para Administradores

## 📋 Estructura de Colecciones

Para que el sistema de autenticación de administradores funcione correctamente, necesitas crear la siguiente colección en Firestore:

### Colección: `administradores`

Esta colección debe contener documentos donde:
- **ID del documento**: El `uid` del usuario de Firebase Auth (se genera automáticamente cuando el usuario se registra)
- **Campos del documento**:
  - `email` (string): El email del administrador
  - `esAdmin` (boolean): Debe ser `true`
  - `nombre` (string, opcional): Nombre del administrador
  - `fechaCreacion` (timestamp, opcional): Fecha de creación del registro

### Ejemplo de Documento:

```json
{
  "email": "admin@ejemplo.com",
  "esAdmin": true,
  "nombre": "Administrador Principal",
  "fechaCreacion": "2024-01-15T10:00:00Z"
}
```

## 🔧 Pasos para Configurar un Administrador

1. **Crear el usuario en Firebase Authentication**:
   - Ve a Firebase Console → Authentication
   - Crea un usuario con email y contraseña

2. **Agregar el usuario a la colección de administradores**:
   - Ve a Firestore Database
   - Crea la colección `administradores` si no existe
   - Crea un documento con el `uid` del usuario como ID
   - Agrega los campos: `email`, `esAdmin: true`

### Método Alternativo (Usando el Email)

También puedes crear documentos usando el email como referencia, pero el sistema busca por email en la colección:

```json
{
  "email": "admin@ejemplo.com",
  "esAdmin": true
}
```

## 🔐 Reglas de Seguridad de Firestore

Asegúrate de configurar reglas de seguridad apropiadas:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Colección de administradores - solo lectura para usuarios autenticados
    match /administradores/{adminId} {
      allow read: if request.auth != null;
      allow write: if false; // Solo se puede escribir manualmente desde la consola
    }
    
    // Otras colecciones...
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## ✅ Verificación

Para verificar que un usuario es administrador:
1. El usuario debe iniciar sesión con su email y contraseña
2. El sistema verificará en Firestore si existe un documento en `administradores` con:
   - `email` igual al email del usuario
   - `esAdmin` igual a `true`

## 📝 Notas Importantes

- Los administradores pueden iniciar sesión tanto desde la pantalla de login normal como desde la pantalla de login de administrador
- La pantalla de login de administrador valida ANTES de permitir el login que el email está en la colección de administradores
- Si un usuario intenta iniciar sesión como admin pero no está en la colección, recibirá un error




