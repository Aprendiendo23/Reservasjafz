# ⚡ Instrucciones Rápidas - Configurar Firebase

## 🎯 Pasos Esenciales (5 minutos)

### 1️⃣ Configurar Reglas (2 min)
1. Ve a: https://console.firebase.google.com/project/recursostic-18bb8/firestore/rules
2. Copia TODO el contenido de `firestore.rules`
3. Pega en el editor
4. Haz clic en **"Publicar"**

### 2️⃣ Crear Usuario Admin (2 min)
1. Ve a: Authentication → Agregar usuario
2. Crea un usuario (ej: admin@ejemplo.com)
3. **Copia el UID** del usuario
4. Ve a: Firestore Database → Datos
5. Crea colección `usuarios`
6. Crea documento con el **UID como ID**
7. Agrega campos:
   - `nombre`: "Administrador"
   - `email`: "admin@ejemplo.com"
   - `rol`: **"admin"** ⚠️
   - `foto`: ""
   - `creado`: timestamp (now)

### 3️⃣ Importar Índices (1 min)
1. Ve a: Firestore Database → Índices
2. Haz clic en **⋮** → **"Importar índices"**
3. Selecciona el archivo `firestore.indexes.json`
4. Haz clic en **"Importar"**
5. Espera 2-5 minutos a que se creen

---

## ✅ Verificar

1. **Reglas:** Deben estar publicadas sin errores
2. **Usuario Admin:** Debe existir con `rol: "admin"`
3. **Índices:** Deben estar en estado "Building" o "Enabled"

---

## 📖 Documentación Completa

Para más detalles, consulta: `CONFIGURAR_FIREBASE_COMPLETO.md`

---

## 🐛 Problemas Comunes

**Error de permisos:**
- Verifica que las reglas estén publicadas
- Espera 10-20 segundos después de publicar

**Falta índice:**
- Firebase te dará un enlace automático
- Haz clic y crea el índice
- Espera a que se cree

**Usuario no es admin:**
- Verifica que el campo `rol` sea exactamente `"admin"` (con comillas)
- El ID del documento debe ser el UID del usuario

