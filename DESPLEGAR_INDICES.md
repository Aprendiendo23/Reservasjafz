# Desplegar Índices de Firestore

## ¿Por qué necesitamos índices?

Firestore requiere índices compuestos cuando haces consultas que combinan múltiples filtros (where) y ordenamientos (orderBy). Sin estos índices, las consultas fallan con errores.

## Índices Agregados

Se ha agregado el siguiente índice crítico:

- **eliminada + fechaUso**: Necesario para consultas que filtran por fecha de uso y estado de eliminación

## Cómo Desplegar los Índices

### Opción 1: Usar el script (Windows)

Ejecuta el archivo `desplegar_indices.bat`:

```bash
desplegar_indices.bat
```

### Opción 2: Comando manual

Ejecuta este comando en la terminal:

```bash
firebase deploy --only firestore:indexes
```

### Opción 3: Crear manualmente en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Selecciona tu proyecto
3. Ve a **Firestore Database** → **Índices**
4. Haz clic en **Crear Índice**
5. Configura el índice con estos campos:
   - Collection ID: `reservas`
   - Campo 1: `eliminada` (Ascendente)
   - Campo 2: `fechaUso` (Ascendente)
6. Haz clic en **Crear**

## Verificar el Estado

Después de desplegar, puedes verificar el estado de los índices en Firebase Console. Los índices pueden tardar unos minutos en crearse.

## Nota Importante

- Los índices se crean automáticamente cuando Firebase detecta que son necesarios (mostrando un enlace en el error)
- Es mejor desplegarlos proactivamente para evitar errores en producción
- Una vez creados, los índices mejoran significativamente el rendimiento de las consultas














