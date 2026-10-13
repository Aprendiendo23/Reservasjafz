# 📊 Cómo Ver la Auditoría en Firestore

## 🔍 Dónde Encontrar las Reservas Eliminadas

### En Firebase Console (Interfaz Web)

1. **Ve a Firebase Console:**
   - https://console.firebase.google.com
   - Selecciona tu proyecto: `recursostic-18bb8`

2. **Navega a Firestore Database:**
   - En el menú lateral, haz clic en **"Firestore Database"**

3. **Busca la colección `reservas`:**
   - En la lista de colecciones, busca **`reservas`**
   - Haz clic en ella

4. **Filtrar reservas eliminadas:**
   - En la barra de búsqueda/filtros, puedes agregar un filtro:
     - Campo: `eliminada`
     - Operador: `==`
     - Valor: `true`

### Campos de Auditoría en las Reservas Eliminadas

Cuando una reserva se elimina, se guardan estos campos para auditoría:

```json
{
  "eliminada": true,
  "fechaEliminacion": "2024-01-30T17:00:00Z",  // Timestamp
  "estado": "eliminada",
  "usuarioEliminacionID": "abc123...",         // ID del usuario que eliminó
  "usuarioEliminacionNombre": "Juan Pérez",    // Nombre del usuario que eliminó
  "eliminadoPorAdmin": true                    // true si fue admin, false si fue docente
}
```

## 📱 En la Aplicación (Pantalla de Auditoría)

Si existe una pantalla de auditoría en la app, deberías poder ver:
- Todas las reservas (activas y eliminadas)
- Filtros para ver solo eliminadas
- Información de quién eliminó y cuándo

## 🔎 Consultas Útiles en Firestore

### Ver todas las reservas eliminadas:

En Firebase Console, puedes usar estos filtros:

1. **Filtro simple:**
   - Campo: `eliminada`
   - Operador: `==`
   - Valor: `true`

2. **Filtro por usuario que eliminó:**
   - Campo: `usuarioEliminacionID`
   - Operador: `==`
   - Valor: `[ID del usuario]`

3. **Filtro por fecha de eliminación:**
   - Campo: `fechaEliminacion`
   - Operador: `>=` o `<=`
   - Valor: `[fecha]`

### Ver reservas eliminadas por admin:

- Campo: `eliminadoPorAdmin`
- Operador: `==`
- Valor: `true`

## 📋 Estructura de Datos de Auditoría

### Reserva Eliminada (Ejemplo):

```json
{
  "id": "reserva123",
  "usuarioID": "docente123",
  "usuarioNombre": "Juan Pérez",
  "recursoID": "laptop1",
  "recursoNombre": "Laptop",
  "dia": "Lunes",
  "hora": "1ª Hora",
  "asignatura": "Matemática",
  "grado": "7A",
  "fechaUso": "2024-02-05T08:00:00Z",
  "creado": "2024-01-25T10:00:00Z",
  
  // Campos de auditoría (agregados al eliminar):
  "eliminada": true,
  "fechaEliminacion": "2024-01-30T17:00:00Z",
  "estado": "eliminada",
  "usuarioEliminacionID": "admin123",
  "usuarioEliminacionNombre": "Admin",
  "eliminadoPorAdmin": true
}
```

## 🔧 Consultas Programáticas

Si quieres consultar desde código, puedes usar:

```dart
// Obtener todas las reservas eliminadas
final eliminadas = await FirebaseFirestore.instance
    .collection('reservas')
    .where('eliminada', isEqualTo: true)
    .orderBy('fechaEliminacion', descending: true)
    .get();

// Obtener reservas eliminadas por un usuario específico
final eliminadasPorUsuario = await FirebaseFirestore.instance
    .collection('reservas')
    .where('eliminada', isEqualTo: true)
    .where('usuarioEliminacionID', isEqualTo: 'usuario123')
    .get();

// Obtener reservas eliminadas por admin
final eliminadasPorAdmin = await FirebaseFirestore.instance
    .collection('reservas')
    .where('eliminada', isEqualTo: true)
    .where('eliminadoPorAdmin', isEqualTo: true)
    .get();
```

## 📊 Resumen

**Ubicación en Firestore:**
- Colección: `reservas`
- Filtro: `eliminada == true`

**Información de Auditoría Disponible:**
- ✅ Quién eliminó (`usuarioEliminacionNombre`, `usuarioEliminacionID`)
- ✅ Cuándo se eliminó (`fechaEliminacion`)
- ✅ Si fue eliminado por admin o docente (`eliminadoPorAdmin`)
- ✅ Todos los datos originales de la reserva (recurso, día, hora, asignatura, etc.)

**Importante:**
- Las reservas **NO se borran permanentemente** de Firestore
- Solo se marcan como `eliminada: true`
- Esto permite auditoría completa y recuperación si es necesario
