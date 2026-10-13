# 📋 Recursos Disponibles para Reservar

## 🔧 Recursos que los Maestros Pueden Reservar

Los siguientes recursos deben estar disponibles en la colección `recursos` de Firestore:

1. **Laptop** (o Lapto)
2. **Proyector**
3. **Tablet** (o Tablets)
4. **Tablet y Proyector** (combinación)

## 📝 Estructura en Firestore

Cada recurso debe tener la siguiente estructura:

```json
{
  "nombre": "Laptop",
  "descripcion": "Laptop para uso educativo",
  "tipo": "laptop",
  "estado": "activo",
  "disponible": true,
  "creado": Timestamp
}
```

## ⏰ Horas y Bloques Disponibles

### Horas Individuales:
- 1ª Hora
- 2ª Hora
- 3ª Hora
- 4ª Hora
- 5ª Hora
- 6ª Hora

### Bloques (Horas Combinadas):
- Bloque 1 (1ª+2ª) - Combina 1ª y 2ª Hora
- Bloque 2 (3ª+4ª) - Combina 3ª y 4ª Hora
- Bloque 3 (5ª+6ª) - Combina 5ª y 6ª Hora

## ⚠️ Lógica Anti-Colisiones

### Reglas de Conflictos:

1. **Si alguien reserva 1ª Hora:**
   - ❌ No se puede reservar Bloque 1 (1ª+2ª)
   - ✅ Se puede reservar 2ª Hora, 3ª Hora, etc.

2. **Si alguien reserva Bloque 1 (1ª+2ª):**
   - ❌ No se puede reservar 1ª Hora
   - ❌ No se puede reservar 2ª Hora
   - ✅ Se puede reservar 3ª Hora, 4ª Hora, etc.

3. **Misma lógica aplica para:**
   - Bloque 2 (3ª+4ª) con 3ª Hora y 4ª Hora
   - Bloque 3 (5ª+6ª) con 5ª Hora y 6ª Hora

## 📢 Mensajes de Error

Cuando un horario o bloque está ocupado, el sistema mostrará:

**"Este horario o bloque ya está ocupado por [Nombre del Docente] en la asignatura '[Asignatura]'"**

Ejemplo:
- "Este horario o bloque ya está ocupado por Juan Pérez en la asignatura 'Matemáticas'"

## 🔍 Verificación de Disponibilidad

El sistema verifica:
1. Si el recurso está disponible en ese día
2. Si hay conflictos con horas individuales vs bloques
3. Muestra información del docente y asignatura que tiene la reserva

