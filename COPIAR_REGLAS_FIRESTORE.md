# 🔴 REGLAS DE FIRESTORE - COPIAR Y PEGAR

## ⚠️ ERROR ACTUAL
Si ves: **"[cloud_firestore/permission-denied] Missing or insufficient permissions"**

**DEBES actualizar las reglas AHORA.**

---

## 📋 PASOS RÁPIDOS (2 minutos)

### 1. Abre Firebase Console
👉 **https://console.firebase.google.com/project/recursostic-18bb8/firestore/rules**

### 2. Copia TODO el siguiente código:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ============================================
    // FUNCIONES AUXILIARES
    // ============================================
    
    // Verificar si el usuario está autenticado
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Verificar si el usuario existe en la colección usuarios
    function userExists() {
      return exists(/databases/$(database)/documents/usuarios/$(request.auth.uid));
    }
    
    // Obtener el rol del usuario actual (solo si existe)
    function getUserRole() {
      return get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.rol;
    }
    
    // Verificar si el usuario es ADMINISTRADOR
    function isAdmin() {
      return isAuthenticated() && 
             userExists() &&
             getUserRole() == 'admin';
    }
    
    // Verificar si el usuario es DOCENTE
    function isDocente() {
      return isAuthenticated() && 
             (userExists() && getUserRole() == 'docente');
    }
    
    // Verificar si el usuario es el propietario del documento
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // ============================================
    // COLECCIÓN: usuarios
    // ============================================
    match /usuarios/{userId} {
      // LECTURA:
      // - Cualquier usuario autenticado puede leer cualquier usuario
      allow read: if isAuthenticated();
      
      // CREACIÓN:
      // - Cualquier usuario autenticado puede crear su propio documento cuando se registra
      // - Admins pueden crear cualquier documento de usuario
      // - Permite crear incluso si el usuario no existe aún (para registro inicial)
      allow create: if isAuthenticated() && 
                       (isOwner(userId) || isAdmin() || !userExists());
      
      // ACTUALIZACIÓN:
      // - Docentes: Solo pueden actualizar su propio documento (perfil)
      // - Admins: Pueden actualizar cualquier documento de usuario
      allow update: if isAuthenticated() && 
                       (isOwner(userId) || isAdmin() || !userExists());
      
      // ELIMINACIÓN:
      // - Solo admins pueden eliminar usuarios
      allow delete: if isAdmin();
    }
    
    // ============================================
    // COLECCIÓN: recursos
    // ============================================
    match /recursos/{recursoId} {
      // LECTURA:
      // - Cualquier usuario autenticado puede leer recursos
      //   (permite que docentes vean disponibilidad incluso si su documento aún no existe)
      allow read: if isAuthenticated();
      
      // CREACIÓN, ACTUALIZACIÓN, ELIMINACIÓN:
      // - Solo admins pueden gestionar recursos (CRUD completo)
      allow create, update, delete: if isAdmin();
    }
    
    // ============================================
    // COLECCIÓN: reservas
    // ============================================
    match /reservas/{reservaId} {
      // LECTURA:
      // - Admins: Pueden leer TODAS las reservas
      // - Docentes: Solo pueden leer sus propias reservas
      // - Permitir lectura si el usuario es el propietario (incluso si no existe en usuarios)
      allow read: if isAuthenticated() && 
                     (isAdmin() || 
                      request.auth.uid == resource.data.usuarioID ||
                      request.auth.uid == resource.data.usuarioId);
      
      // CREACIÓN:
      // - Cualquier usuario autenticado puede crear reservas propias
      //   (verifica que el usuarioID/usuarioId coincida con el usuario autenticado)
      // - Permite crear incluso si el usuario no existe en la colección usuarios
      allow create: if isAuthenticated() && 
                       (request.resource.data.usuarioID == request.auth.uid ||
                        request.resource.data.usuarioId == request.auth.uid ||
                        isAdmin());
      
      // ACTUALIZACIÓN:
      // - Docentes: Solo pueden actualizar sus propias reservas
      // - Admins: Pueden actualizar CUALQUIER reserva
      allow update: if isAuthenticated() && 
                       (isAdmin() || 
                        request.auth.uid == resource.data.usuarioID ||
                        request.auth.uid == resource.data.usuarioId);
      
      // ELIMINACIÓN:
      // - Docentes: Solo pueden eliminar sus propias reservas
      // - Admins: Pueden eliminar CUALQUIER reserva
      allow delete: if isAuthenticated() && 
                       (isAdmin() || 
                        request.auth.uid == resource.data.usuarioID ||
                        request.auth.uid == resource.data.usuarioId);
    }
    
    // ============================================
    // REGLA POR DEFECTO: Denegar todo lo demás
    // ============================================
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### 3. Pega en el editor de Firebase Console

### 4. Haz clic en "Publicar" (botón azul arriba)

### 5. Espera 10-20 segundos

### 6. Cierra y vuelve a abrir la aplicación

---

## ✅ Después de Actualizar

La aplicación debería funcionar correctamente y podrás:
- ✅ Ver el selector de recursos
- ✅ Crear reservas
- ✅ Ver disponibilidad
- ✅ Ver tus reservas

---

## 🔧 Si el Error Persiste

1. Verifica que las reglas se publicaron correctamente (debería aparecer un mensaje de éxito)
2. Revisa que no haya errores de sintaxis (aparecerán en rojo en el editor)
3. Asegúrate de estar autenticado en la aplicación
4. Espera unos segundos más (las reglas pueden tardar en aplicarse globalmente)

---

**IMPORTANTE:** Sin actualizar las reglas, NO podrás usar la aplicación.

