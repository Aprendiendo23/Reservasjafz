# 🔥 Configuración Completa de Firebase

Este documento te guiará paso a paso para configurar todas las colecciones, reglas e índices necesarios en Firebase.

## 📋 Requisitos Previos

1. Tener una cuenta de Firebase
2. Tener el proyecto `recursostic-18bb8` creado
3. Tener Firestore Database habilitado

---

## 🚀 PASO 1: Configurar Reglas de Firestore

### Opción A: Usando Firebase Console (Recomendado)

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto: **recursostic-18bb8**
3. En el menú lateral, haz clic en **Firestore Database**
4. Ve a la pestaña **"Reglas"** (Rules)
5. Copia TODO el contenido del archivo `firestore.rules` de este proyecto
6. Pega el contenido en el editor de reglas
7. Haz clic en **"Publicar"** (Publish)
8. Espera 10-20 segundos para que se apliquen los cambios

### Opción B: Usando Firebase CLI

```bash
# Si tienes Firebase CLI instalado
firebase deploy --only firestore:rules
```

---

## 📊 PASO 2: Crear las Colecciones

Las colecciones se crearán automáticamente cuando se agreguen los primeros documentos. Sin embargo, puedes crear documentos de ejemplo para probar.

### Colección: `usuarios`

**Estructura del documento:**
```json
{
  "nombre": "Juan Pérez",
  "email": "juan@ejemplo.com",
  "rol": "docente",  // o "admin"
  "foto": "https://...",
  "creado": Timestamp
}
```

**Crear primer usuario admin (IMPORTANTE):**

1. Ve a Firestore Database → **"Datos"** (Data)
2. Haz clic en **"Iniciar colección"** (Start collection)
3. ID de colección: `usuarios`
4. ID del documento: Usa el **UID del usuario admin** (puedes obtenerlo desde Authentication)
5. Agrega los siguientes campos:
   - `nombre` (string): "Administrador"
   - `email` (string): "admin@ejemplo.com"
   - `rol` (string): **"admin"** ⚠️ IMPORTANTE
   - `foto` (string): "" (vacío)
   - `creado` (timestamp): Selecciona "timestamp" y usa "now"

### Colección: `recursos`

**Estructura del documento:**
```json
{
  "nombre": "Proyector 1",
  "descripcion": "Proyector Epson",
  "tipo": "proyector",
  "estado": "activo",
  "disponible": true,
  "creado": Timestamp
}
```

**Crear recurso de ejemplo:**

1. Haz clic en **"Iniciar colección"**
2. ID de colección: `recursos`
3. ID del documento: Genera automáticamente
4. Agrega los campos:
   - `nombre` (string): "Proyector 1"
   - `descripcion` (string): "Proyector Epson"
   - `tipo` (string): "proyector"
   - `estado` (string): "activo"
   - `disponible` (boolean): true
   - `creado` (timestamp): now

### Colección: `reservas`

**Estructura del documento:**
```json
{
  "usuarioID": "uid_del_usuario",
  "recursoID": "id_del_recurso",
  "dia": "2024-01-15",
  "hora": "09:00",
  "fechaInicio": Timestamp,
  "fechaFin": Timestamp,
  "estado": "activa",
  "creado": Timestamp
}
```

**Nota:** Esta colección se creará automáticamente cuando los usuarios hagan reservas.

---

## 🔍 PASO 3: Configurar Índices

Los índices son necesarios para que las consultas complejas funcionen correctamente.

### Opción A: Usando Firebase Console

1. Ve a Firestore Database → **"Índices"** (Indexes)
2. Haz clic en **"Crear índice"** (Create index)
3. Crea los siguientes índices uno por uno:

#### Índice 1: Reservas por Usuario y Estado
- **Colección:** `reservas`
- **Campos:**
  - `usuarioID` (Ascendente)
  - `estado` (Ascendente)
  - `fechaInicio` (Ascendente)

#### Índice 2: Reservas por Día, Hora y Recurso
- **Colección:** `reservas`
- **Campos:**
  - `dia` (Ascendente)
  - `hora` (Ascendente)
  - `recursoID` (Ascendente)

#### Índice 3: Reservas por Recurso y Estado
- **Colección:** `reservas`
- **Campos:**
  - `recursoID` (Ascendente)
  - `estado` (Ascendente)
  - `fechaInicio` (Ascendente)

#### Índice 4: Usuarios por Email y Rol
- **Colección:** `usuarios`
- **Campos:**
  - `email` (Ascendente)
  - `rol` (Ascendente)

#### Índice 5: Usuarios por Rol
- **Colección:** `usuarios`
- **Campos:**
  - `rol` (Ascendente)

#### Índice 6: Recursos por Estado
- **Colección:** `recursos`
- **Campos:**
  - `estado` (Ascendente)

### Opción B: Usando Firebase CLI (Más Rápido)

1. Asegúrate de tener el archivo `firestore.indexes.json` en la raíz del proyecto
2. Ejecuta:
```bash
firebase deploy --only firestore:indexes
```

### Opción C: Importar desde el archivo JSON

1. Ve a Firestore Database → **"Índices"** (Indexes)
2. Haz clic en los **tres puntos** (⋮) → **"Importar índices"** (Import indexes)
3. Selecciona el archivo `firestore.indexes.json` de este proyecto
4. Haz clic en **"Importar"**

**Nota:** Los índices pueden tardar varios minutos en crearse. Firebase te notificará cuando estén listos.

---

## ✅ PASO 4: Verificar la Configuración

### Verificar Reglas:
1. Ve a Firestore Database → **"Reglas"**
2. Deberías ver las reglas que copiaste
3. Verifica que no haya errores de sintaxis (aparecerán en rojo)

### Verificar Índices:
1. Ve a Firestore Database → **"Índices"**
2. Deberías ver 6 índices en estado "Building" o "Enabled"
3. Si alguno está en "Error", haz clic para ver los detalles

### Verificar Colecciones:
1. Ve a Firestore Database → **"Datos"**
2. Deberías poder ver las colecciones: `usuarios`, `recursos`, `reservas` (si ya creaste documentos)

---

## 🎯 PASO 5: Crear Usuario Administrador

**IMPORTANTE:** Necesitas crear al menos un usuario con rol "admin" para poder usar las funciones de administrador.

### Método 1: Desde Authentication + Firestore

1. Ve a **Authentication** → **"Usuarios"**
2. Haz clic en **"Agregar usuario"** (Add user)
3. Ingresa un email y contraseña (ej: admin@ejemplo.com)
4. Copia el **UID** del usuario creado
5. Ve a **Firestore Database** → **"Datos"**
6. Crea un documento en la colección `usuarios` con:
   - **ID del documento:** El UID que copiaste
   - **Campos:**
     - `nombre`: "Administrador"
     - `email`: "admin@ejemplo.com"
     - `rol`: **"admin"** ⚠️
     - `foto`: ""
     - `creado`: Timestamp (now)

### Método 2: Desde la App (si ya tienes un usuario)

1. Inicia sesión en la app con cualquier usuario
2. Ve a Firebase Console → Firestore Database
3. Busca el documento del usuario en la colección `usuarios`
4. Cambia el campo `rol` de "docente" a **"admin"**

---

## 🐛 Solución de Problemas

### Error: "Missing or insufficient permissions"
- **Causa:** Las reglas no están configuradas o hay un error en ellas
- **Solución:** 
  1. Verifica que las reglas estén publicadas
  2. Revisa que no haya errores de sintaxis
  3. Espera 10-20 segundos después de publicar

### Error: "The query requires an index"
- **Causa:** Falta un índice para una consulta específica
- **Solución:**
  1. Firebase te dará un enlace para crear el índice automáticamente
  2. Haz clic en el enlace y crea el índice
  3. Espera a que se cree (puede tardar varios minutos)

### Error: "User is not admin"
- **Causa:** El usuario no tiene rol "admin" en Firestore
- **Solución:**
  1. Verifica en Firestore que el documento del usuario tenga `rol: "admin"`
  2. Asegúrate de que el ID del documento coincida con el UID del usuario

---

## 📝 Resumen de Estructura

```
Firestore Database
├── usuarios/
│   ├── {userId}/
│   │   ├── nombre: string
│   │   ├── email: string
│   │   ├── rol: "docente" | "admin"
│   │   ├── foto: string
│   │   └── creado: timestamp
│
├── recursos/
│   ├── {recursoId}/
│   │   ├── nombre: string
│   │   ├── descripcion: string
│   │   ├── tipo: string
│   │   ├── estado: "activo" | "inactivo"
│   │   ├── disponible: boolean
│   │   └── creado: timestamp
│
└── reservas/
    ├── {reservaId}/
    │   ├── usuarioID: string
    │   ├── recursoID: string
    │   ├── dia: string
    │   ├── hora: string
    │   ├── fechaInicio: timestamp
    │   ├── fechaFin: timestamp
    │   ├── estado: "activa" | "cancelada" | "completada"
    │   └── creado: timestamp
```

---

## ✅ Checklist Final

- [ ] Reglas de Firestore configuradas y publicadas
- [ ] Índices creados (6 índices)
- [ ] Colección `usuarios` creada
- [ ] Colección `recursos` creada (opcional, se crea automáticamente)
- [ ] Colección `reservas` (se crea automáticamente)
- [ ] Usuario administrador creado con `rol: "admin"`
- [ ] Probado login como docente
- [ ] Probado login como admin

---

¡Listo! Tu Firebase está configurado correctamente. 🎉

