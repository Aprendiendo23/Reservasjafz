# 🔥 Actualizar Reglas de Firestore

## ⚠️ IMPORTANTE: Error de Permisos

Si estás viendo el error: `[cloud_firestore/permission-denied] Missing or insufficient permissions`

Necesitas actualizar las reglas de Firestore en Firebase Console.

## 📋 Pasos para Actualizar las Reglas

### 1. Ve a Firebase Console
1. Abre: https://console.firebase.google.com/project/recursostic-18bb8/firestore/rules
2. O ve a: Firebase Console → Firestore Database → Reglas

### 2. Copia las Nuevas Reglas
Copia **TODO** el contenido del archivo `firestore.rules` de este proyecto.

### 3. Pega y Publica
1. Pega el contenido en el editor de reglas
2. Haz clic en **"Publicar"** (Publish)
3. Espera 10-20 segundos para que se apliquen

## ✅ Cambios Realizados

Las nuevas reglas permiten:

1. **Crear Reservas:**
   - Cualquier usuario autenticado puede crear reservas propias
   - No requiere que el usuario exista en la colección `usuarios` primero
   - Verifica que `usuarioID` coincida con el usuario autenticado

2. **Crear/Actualizar Usuario:**
   - Permite crear el documento de usuario incluso si no existe
   - Facilita el registro inicial de usuarios

3. **Leer Reservas:**
   - Admins pueden leer todas las reservas
   - Docentes pueden leer solo sus propias reservas
   - Basado en el campo `usuarioID` de la reserva

## 🔍 Verificación

Después de actualizar las reglas:

1. **Espera 10-20 segundos** después de publicar
2. **Cierra y vuelve a abrir la aplicación**
3. **Intenta crear una reserva nuevamente**

Si el error persiste:
- Verifica que las reglas se publicaron correctamente
- Revisa que no haya errores de sintaxis en las reglas
- Asegúrate de estar autenticado en la aplicación

## 📝 Nota

Las reglas ahora son más permisivas para facilitar el registro y creación de reservas, pero mantienen la seguridad:
- Solo usuarios autenticados pueden crear reservas
- Solo pueden crear reservas con su propio `usuarioID`
- Los admins tienen acceso completo

