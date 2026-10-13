# 🔥 Desplegar Reglas de Firestore para Asignaturas

## ⚠️ IMPORTANTE
Las reglas de Firestore deben actualizarse para que los administradores puedan gestionar asignaturas.

---

## 🚀 Método 1: Usando el Script (Recomendado)

Ejecuta el script desde la terminal:

```bash
cd /home/antonio/Documentos/reservas_recursos
./desplegar_reglas.sh
```

Si Firebase CLI no está configurado, el script te dará instrucciones manuales.

---

## 📋 Método 2: Manual (Firebase Console)

### Paso 1: Abre Firebase Console
👉 **https://console.firebase.google.com/project/recursostic-18bb8/firestore/rules**

### Paso 2: Copia las Reglas
Abre el archivo `firestore.rules` en este proyecto y copia **TODO** su contenido.

### Paso 3: Pega en Firebase Console
1. Pega el contenido completo en el editor de reglas
2. Verifica que no haya errores de sintaxis (aparecerán en rojo)
3. Haz clic en el botón **"Publicar"** (Publish) en la parte superior

### Paso 4: Espera
Espera 10-20 segundos para que las reglas se apliquen globalmente.

---

## ✅ Verificación

Después de desplegar las reglas:

1. **Cierra completamente la aplicación** (si está abierta)
2. **Vuelve a abrirla**
3. **Inicia sesión como administrador**
4. **Ve a "Gestión de Asignaturas"**
5. **Intenta crear una asignatura**

Si todo funciona correctamente, deberías poder:
- ✅ Crear asignaturas
- ✅ Editar asignaturas
- ✅ Activar/Desactivar asignaturas
- ✅ Eliminar asignaturas

---

## 🔍 Reglas Incluidas

Las nuevas reglas incluyen:

```javascript
// COLECCIÓN: asignaturas
match /asignaturas/{asignaturaId} {
  // LECTURA: Cualquier usuario autenticado puede leer
  allow read: if isAuthenticated();
  
  // CREACIÓN, ACTUALIZACIÓN, ELIMINACIÓN: Solo admins
  allow create, update, delete: if isAdmin();
}
```

---

## ❌ Si el Error Persiste

1. **Verifica que las reglas se publicaron correctamente:**
   - Debería aparecer un mensaje de éxito en Firebase Console
   - La fecha de última actualización debería cambiar

2. **Verifica que estás autenticado como admin:**
   - Tu usuario debe tener `rol: 'admin'` en la colección `usuarios`

3. **Espera unos minutos:**
   - Las reglas pueden tardar en propagarse globalmente

4. **Revisa la consola de la aplicación:**
   - Busca mensajes de error específicos

---

## 📞 Soporte

Si después de seguir estos pasos el error persiste, verifica:
- Que el proyecto de Firebase sea correcto: `recursostic-18bb8`
- Que tu usuario tenga permisos de administrador en Firestore
- Que no haya errores de sintaxis en las reglas
