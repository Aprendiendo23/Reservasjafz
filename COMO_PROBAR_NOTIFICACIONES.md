# 🧪 Cómo Probar las Notificaciones

## ✅ Lo que Funciona AHORA (sin Cloud Functions)

### Notificaciones Dentro de la App
- ✅ Cuando un docente crea una reserva, se crean notificaciones en Firestore
- ✅ Todos los usuarios (excepto el que creó la reserva) reciben una notificación
- ✅ Las notificaciones incluyen: día, hora/bloque, recurso, aula, asignatura

## 📱 Cómo Probar

### Paso 1: Preparar Dispositivos/Usuarios

1. **Usuario 1 (Docente):**
   - Abre la app
   - Inicia sesión como docente
   - Ve a crear una reserva

2. **Usuario 2 (Otro usuario):**
   - Abre la app en otro dispositivo (o cierra sesión y entra con otra cuenta)
   - Inicia sesión con otra cuenta de usuario
   - Mantén la app abierta

### Paso 2: Crear una Reserva

1. Como **Usuario 1 (Docente)**:
   - Ve a "Crear Reserva"
   - Completa el formulario:
     - Selecciona un recurso
     - Selecciona fecha y día
     - Selecciona hora o bloque
     - Selecciona asignatura
     - Selecciona grado/aula
   - Haz clic en "Crear Reserva" o "Guardar"

### Paso 3: Verificar Notificaciones

**En la app del Usuario 2:**
- Deberías ver que se creó una notificación en Firestore
- La notificación contiene toda la información de la reserva

**Para ver las notificaciones en la app:**
- Necesitarías crear una pantalla de notificaciones (opcional, por ahora)
- O verificar en Firebase Console > Firestore > `notificaciones`

## 🔍 Verificar en Firebase Console

1. Ve a: https://console.firebase.google.com
2. Selecciona tu proyecto: `recursostic-18bb8`
3. Ve a **Firestore Database**
4. Busca la colección `notificaciones`
5. Deberías ver documentos con:
   - `usuarioID`: ID del usuario que recibió la notificación
   - `titulo`: "Nueva Reserva Creada"
   - `mensaje`: Detalles de la reserva
   - `tipo`: "nueva_reserva"
   - `leida`: false
   - `creado`: Timestamp

## 📊 Verificar Tokens FCM

Para verificar que los tokens se están guardando:

1. En Firebase Console > Firestore
2. Busca la colección `fcm_tokens`
3. Deberías ver documentos con:
   - `usuarioID`: ID del usuario
   - `token`: Token FCM del dispositivo
   - `actualizado`: Timestamp

## 🎯 Prueba Completa

### Escenario de Prueba:

1. **Dispositivo 1:** 
   - Usuario: docente1@gmail.com
   - Rol: docente
   - Acción: Crear una reserva

2. **Dispositivo 2:**
   - Usuario: docente2@gmail.com
   - Rol: docente
   - Estado: App abierta

3. **Resultado Esperado:**
   - En Firestore > `notificaciones`: Se crea un documento para `docente2`
   - El documento contiene toda la información de la reserva
   - El campo `leida` está en `false`

## 🔔 Notificaciones Push (Futuro)

Para que las notificaciones push funcionen (cuando la app está cerrada):
- Necesitas actualizar el plan de Firebase a Blaze
- Desplegar Cloud Functions
- Ver instrucciones en: `DESPLIEGUE_CLOUD_FUNCTIONS.md`

## ✅ Checklist de Prueba

- [ ] Dos usuarios diferentes iniciaron sesión
- [ ] Usuario 1 creó una reserva
- [ ] En Firestore > `notificaciones` aparece un documento para Usuario 2
- [ ] El documento contiene: día, hora, recurso, aula, asignatura
- [ ] En Firestore > `fcm_tokens` hay tokens guardados
- [ ] En Firestore > `push_notifications_queue` se crea un documento (aunque no se procese sin Cloud Functions)

## 🐛 Si No Funciona

1. **No se crean notificaciones:**
   - Verifica que el usuario que crea la reserva es diferente al que debería recibirla
   - Revisa los logs de la consola de Flutter
   - Verifica las reglas de Firestore

2. **No se guardan tokens FCM:**
   - Verifica que el usuario dio permisos de notificaciones
   - Revisa los logs: deberías ver "✅ Token FCM guardado"
   - Verifica que FCM se inicializó correctamente

3. **Error al crear reserva:**
   - Verifica que todos los campos están completos
   - Revisa los logs de error
   - Verifica la conexión a Firebase

## 📝 Logs a Revisar

En la consola de Flutter deberías ver:

```
✅ Firebase inicializado correctamente
✅ FCM inicializado correctamente
📱 Token FCM obtenido: ...
✅ Token FCM guardado para usuario: ...
📝 Creando reserva con datos: ...
✅ Reserva creada con ID: ...
✅ Notificaciones en Firestore creadas para X usuarios
✅ Push notification encolada para X dispositivos
```
