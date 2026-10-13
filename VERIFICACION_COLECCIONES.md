# ✅ Verificación de Nombres de Colecciones

## 📋 Colecciones en el Código

### ✅ Colecciones Correctas:

1. **`usuarios`** ✅
   - Usado en: `usuario_service.dart`, `auth_service.dart`
   - Todos los usos son consistentes: `'usuarios'`

2. **`recursos`** ✅
   - Usado en: `recurso_service.dart`
   - Todos los usos son consistentes: `'recursos'`

3. **`reservas`** ✅
   - Usado en: `reserva_service.dart`
   - Todos los usos son consistentes: `'reservas'`

## 🔍 Campos en las Colecciones

### Colección: `usuarios`
- `nombre` ✅
- `email` ✅
- `rol` ✅ (valores: "docente" | "admin")
- `foto` ✅
- `creado` ✅ (timestamp)

### Colección: `recursos`
- `nombre` ✅
- `descripcion` ✅
- `tipo` ✅
- `estado` ✅ (valores: "activo" | "inactivo")
- `disponible` ✅ (boolean)
- `creado` ✅ (timestamp)

### Colección: `reservas`
- `usuarioID` ✅ (string - UID del usuario)
- `recursoID` ✅ (string - ID del recurso)
- `dia` ✅ (string - formato: "YYYY-MM-DD")
- `hora` ✅ (string - formato: "HH:mm")
- `fechaInicio` ✅ (timestamp)
- `fechaFin` ✅ (timestamp)
- `estado` ✅ (valores: "activa" | "cancelada" | "completada")
- `usuarioEmail` ✅ (string - email del usuario)
- `usuarioNombre` ✅ (string - nombre del usuario)
- `creado` ✅ (timestamp)

## ⚠️ Nota sobre Nombres de Campos

**IMPORTANTE:** En el código se usan **MAYÚSCULAS** para algunos campos:
- `usuarioID` (no `usuarioId`)
- `recursoID` (no `recursoId`)

Esto es consistente en todo el código. Las reglas de Firestore también están configuradas para aceptar ambos formatos (`usuarioID` y `usuarioId`) por compatibilidad.

## ✅ Conclusión

**Todas las colecciones están correctamente escritas y son consistentes en todo el código.**

Los nombres son:
- ✅ `usuarios` (minúsculas, plural)
- ✅ `recursos` (minúsculas, plural)
- ✅ `reservas` (minúsculas, plural)

## 📝 Recomendación

Asegúrate de que en Firebase Console las colecciones se llamen exactamente:
- `usuarios` (no `Usuario`, `Usuarios`, `usuario`)
- `recursos` (no `Recurso`, `Recursos`, `recurso`)
- `reservas` (no `Reserva`, `Reservas`, `reserva`)

Los nombres son **case-sensitive** en Firestore.

