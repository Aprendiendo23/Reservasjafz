# 🔐 Configuración de Reglas de Seguridad de Firestore

## ⚠️ IMPORTANTE: Error de Permisos

Si ves el error **"Missing or insufficient permissions"**, necesitas configurar las reglas de seguridad de Firestore.

## 📋 Pasos para Configurar las Reglas

### 1. Abre Firebase Console
1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto: **recursostic-18bb8**

### 2. Ve a Firestore Database
1. En el menú lateral, haz clic en **"Firestore Database"**
2. Ve a la pestaña **"Reglas"** (Rules)

### 3. Copia y Pega las Reglas

Copia el contenido del archivo `firestore.rules` y pégalo en el editor de reglas de Firebase Console.

### 4. Publica las Reglas
1. Haz clic en el botón **"Publicar"** (Publish)
2. Espera a que se publiquen (puede tardar unos segundos)

## 📝 Reglas Incluidas

Las reglas están diferenciadas por rol:

### 👨‍🏫 **DOCENTES** pueden:

✅ **Colección `usuarios`:**
- Leer cualquier usuario (para ver información básica)
- Crear/actualizar su propio documento (al registrarse y editar perfil)
- ❌ NO pueden eliminar usuarios

✅ **Colección `recursos`:**
- Leer todos los recursos (para ver disponibilidad y crear reservas)
- ❌ NO pueden crear, actualizar ni eliminar recursos

✅ **Colección `reservas`:**
- Crear sus propias reservas
- Leer solo sus propias reservas
- Actualizar solo sus propias reservas
- Eliminar solo sus propias reservas
- ❌ NO pueden ver ni modificar reservas de otros docentes

### 👨‍💼 **ADMINISTRADORES** pueden:

✅ **Colección `usuarios`:**
- Leer cualquier usuario
- Crear cualquier documento de usuario
- Actualizar cualquier documento de usuario
- Eliminar usuarios

✅ **Colección `recursos`:**
- Leer todos los recursos
- Crear recursos nuevos
- Actualizar recursos existentes
- Eliminar recursos

✅ **Colección `reservas`:**
- Leer TODAS las reservas (de todos los docentes)
- Crear reservas (aunque normalmente no lo harán)
- Actualizar CUALQUIER reserva
- Eliminar CUALQUIER reserva

## 🚨 Reglas Temporales para Desarrollo (NO USAR EN PRODUCCIÓN)

Si necesitas probar rápidamente, puedes usar estas reglas temporales (solo para desarrollo):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

⚠️ **ADVERTENCIA**: Estas reglas permiten que cualquier usuario autenticado pueda leer y escribir todo. Úsalas SOLO para desarrollo y pruebas.

## ✅ Verificación

Después de publicar las reglas:
1. Vuelve a la aplicación
2. Haz clic en "Ir al Login"
3. Inicia sesión nuevamente
4. Deberías poder acceder sin errores de permisos

## 🔍 Estructura de Colecciones

Asegúrate de que estas colecciones existan en Firestore:

- **usuarios**: Información de usuarios (rol, nombre, email, etc.)
- **recursos**: Recursos disponibles para reservar
- **reservas**: Reservas realizadas por los usuarios

## 📞 Si Persisten los Problemas

1. Verifica que el usuario esté autenticado correctamente
2. Verifica que el documento del usuario exista en la colección `usuarios`
3. Verifica que las reglas se hayan publicado correctamente
4. Espera unos minutos después de publicar las reglas (puede haber un pequeño retraso)

