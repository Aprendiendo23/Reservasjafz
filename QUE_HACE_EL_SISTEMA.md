# 📋 ¿QUÉ HACE EL SISTEMA?

## 🎯 Propósito General

El sistema es una **aplicación de gestión de reservas de recursos educativos** que permite a los maestros reservar equipos tecnológicos (Laptops, Proyectores, Tablets) para uso en sus clases, y a los administradores gestionar y auditar todas las reservas.

---

## 👥 USUARIOS DEL SISTEMA

### 1. **DOCENTES (Maestros)**
- Pueden crear reservas de recursos
- Ver su cronograma de disponibilidad
- Ver sus propias reservas
- Eliminar sus reservas (se marcan como eliminadas para auditoría)

### 2. **ADMINISTRADORES**
- Todo lo que pueden hacer los docentes
- Gestionar recursos (crear, editar, eliminar)
- Ver TODAS las reservas de todos los maestros
- Ver auditoría completa (incluyendo reservas eliminadas)
- Gestionar usuarios
- Exportar datos

---

## 🔐 AUTENTICACIÓN Y ACCESO

### Login de Docentes
- Registro con email y contraseña
- Inicio de sesión con email y contraseña
- Inicio de sesión con Google
- Recuperación de contraseña

### Login de Administradores
- Login separado para administradores
- Requiere credenciales de admin

---

## 📅 CREAR RESERVA

### Proceso de Reserva:
1. **Seleccionar Día**: Lunes, Martes, Miércoles, Jueves o Viernes
2. **Seleccionar Hora o Bloque**:
   - Horas individuales: 1ª Hora, 2ª Hora, 3ª Hora, 4ª Hora, 5ª Hora, 6ª Hora
   - Bloques: 
     - Bloque 1 (1ª+2ª Hora)
     - Bloque 2 (3ª+4ª Hora)
     - Bloque 3 (5ª+6ª Hora)
3. **Seleccionar Asignatura**:
   - Lengua y Literatura (LyL)
   - Matemática (MATEM)
   - Inglés
   - Ciencias Sociales (CS / CCSS)
   - Ciencias Naturales (CN / CCNN)
   - Física
   - Química
   - Biología
   - Creciendo en Valores (CV)
   - AEP (Acompañamiento Educativo Pedagógico)
   - TAC
   - Educación Física
4. **Seleccionar Docente**:
   - Marlon Rodríguez
   - Marling Requene
   - Elba Ruth Calero
   - Hollman Ñamendi
   - Judith Rivas
   - Martin López
   - Marlon Ruiz
   - Ali López
   - Director Guillermo Martinez
   - Subdirector Edwin Prado
5. **Seleccionar Recurso**:
   - Laptop
   - Laptop y Proyector
   - Tablet y Proyector
   - Proyector
   - Tablet

### Validaciones:
- ✅ Verifica que el horario no esté ocupado
- ✅ Detecta conflictos entre horas individuales y bloques
- ✅ Muestra mensaje de error si está ocupado (con nombre del docente y asignatura)
- ✅ Muestra mensaje flotante de éxito al crear la reserva

---

## 📊 CRONOGRAMA (Vista Principal)

### Dos Vistas Disponibles:

#### 1. **Vista Calendario (Tabla Semanal)**
- Muestra la semana seleccionada (Lunes a Viernes)
- Filas: Horas (1ª Hora a 6ª Hora)
- Columnas: Días de la semana
- **Selector de Semana**:
  - Flechas para navegar semanas anteriores/siguientes
  - Botón para seleccionar fecha específica (abre calendario)
  - Muestra rango de la semana (del lunes al viernes)
- **Celdas**:
  - 🟢 Verde = Disponible
  - 🟠 Naranja = Ocupado (muestra: Docente, Asignatura, Hora/Bloque)
- Clic en celda disponible → Crea reserva con día y hora preseleccionados

#### 2. **Vista Tabla (Lista de Reservas)**
- Tabla con columnas:
  - **MAESTRO SOLICITANTE**: Nombre del docente
  - **RECURSO**: Recurso reservado
  - **FECHA SOLICITUD**: Fecha en que se creó la reserva (dd-MM-yyyy)
  - **FECHA DE USO**: Día de la semana (Lunes, Martes, etc.)
  - **HORARIO QUE SE UTILIZARA**: Hora o bloque reservado
- Muestra todas las reservas del recurso seleccionado
- Se actualiza automáticamente cuando se crea una nueva reserva

---

## 🛡️ SISTEMA DE AUDITORÍA

### Eliminación Lógica (Soft Delete):
- ❌ **NO se eliminan físicamente** las reservas
- ✅ Se marcan como `eliminada: true`
- ✅ Se guarda la fecha de eliminación
- ✅ Permite mantener historial completo para auditoría

### Para Usuarios Normales:
- Solo ven reservas activas (no eliminadas)
- Las reservas eliminadas desaparecen de su vista
- No pueden ver el historial de eliminaciones

### Para Administradores:
- **Vista de Auditoría** especial:
  - Muestra TODAS las reservas (activas y eliminadas)
  - Reservas eliminadas aparecen en rojo
  - Muestra fecha de eliminación
  - Estadísticas: Total activas vs eliminadas
  - Columnas completas: Maestro, Recurso, Fecha Solicitud, Fecha de Uso, Horario, Estado

---

## 🔍 VERIFICACIÓN DE DISPONIBILIDAD

### Lógica Anti-Colisiones:

#### Conflictos Detectados:
1. **Hora Individual vs Bloque**:
   - Si alguien reserva "1ª Hora" → No se puede reservar "Bloque 1"
   - Si alguien reserva "Bloque 1" → No se puede reservar "1ª Hora" ni "2ª Hora"

2. **Bloque vs Bloque**:
   - Si alguien reserva "Bloque 1" → No se puede reservar "Bloque 1" (mismo bloque)
   - Bloques diferentes no chocan (Bloque 1 vs Bloque 2 está permitido)

3. **Hora vs Hora**:
   - Si alguien reserva "1ª Hora" → No se puede reservar "1ª Hora" (misma hora)

### Mensajes de Error:
- Muestra nombre del docente que tiene la reserva
- Muestra la asignatura
- Muestra el horario ocupado

---

## 📱 PANTALLAS PRINCIPALES

### Para Docentes:
1. **Home Docente**: Menú principal con opciones
2. **Cronograma**: Ver disponibilidad y crear reservas
3. **Crear Reserva**: Formulario completo de reserva
4. **Mis Reservas**: Ver y eliminar sus propias reservas
5. **Perfil**: Información del usuario

### Para Administradores:
1. **Panel de Administración**: Dashboard con estadísticas
2. **Gestión de Recursos**: Crear, editar, eliminar recursos
3. **Gestión de Reservas**: Ver todas las reservas con filtros
4. **Cronograma**: Ver cronograma de cualquier recurso
5. **Auditoría de Reservas**: Ver todas las reservas incluyendo eliminadas
6. **Gestión de Usuarios**: Ver todos los docentes
7. **Exportar Datos**: Exportar a PDF o Excel

---

## 💾 ALMACENAMIENTO DE DATOS

### Firestore Collections:

#### 1. **usuarios**
- Información de usuarios (docentes y admins)
- Campos: nombre, email, rol, foto, creado

#### 2. **recursos**
- Recursos disponibles para reservar
- Campos: nombre, descripción, tipo, estado, creado

#### 3. **reservas**
- Todas las reservas creadas
- Campos:
  - `usuarioID`: ID del usuario que creó la reserva
  - `usuarioNombre`: Nombre del usuario
  - `docente`: Docente que usará el recurso
  - `recursoID`: ID del recurso
  - `recursoNombre`: Nombre del recurso
  - `dia`: Día de la semana (Lunes, Martes, etc.)
  - `hora`: Hora o bloque (1ª Hora, Bloque 1, etc.)
  - `asignatura`: Asignatura
  - `estado`: 'activa' o 'eliminada'
  - `eliminada`: true/false (para auditoría)
  - `fechaEliminacion`: Timestamp (si fue eliminada)
  - `creado`: Timestamp de creación

---

## 🔄 ACTUALIZACIÓN EN TIEMPO REAL

- Usa **StreamBuilder** de Flutter
- Las reservas se actualizan automáticamente cuando:
  - Se crea una nueva reserva
  - Se elimina una reserva
  - Se modifica una reserva
- No requiere refrescar manualmente

---

## 🎨 CARACTERÍSTICAS DE DISEÑO

- **Material Design 3**: Diseño moderno y consistente
- **Colores**: Esquema de colores basado en azul
- **Gradientes**: Fondos con gradientes suaves
- **Iconos**: Iconos descriptivos en cada sección
- **Mensajes**: Mensajes flotantes (SnackBar) para feedback
- **Responsive**: Se adapta a diferentes tamaños de pantalla

---

## 🔒 SEGURIDAD Y PERMISOS

### Reglas de Firestore:
- Usuarios autenticados pueden leer recursos
- Solo admins pueden crear/editar/eliminar recursos
- Usuarios pueden crear sus propias reservas
- Usuarios pueden leer/editar/eliminar solo sus reservas
- Admins pueden leer/editar/eliminar todas las reservas

---

## 📈 FUNCIONALIDADES ESPECIALES

### 1. **Recursos por Defecto**
- Laptop, Proyector, Tablet siempre disponibles
- No requieren estar en Firestore
- Aparecen con icono de estrella en los selectores

### 2. **Bloques de Horas**
- Permite reservar múltiples horas consecutivas
- Facilita reservas de clases largas
- Detecta conflictos automáticamente

### 3. **Selector de Semana**
- Navegación fácil entre semanas
- Selección de fecha específica
- Muestra rango completo de la semana

### 4. **Auditoría Completa**
- Historial de todas las reservas
- Incluye reservas eliminadas
- Fecha de eliminación registrada
- Solo visible para administradores

---

## 🚀 FLUJO TÍPICO DE USO

### Docente crea una reserva:
1. Inicia sesión
2. Va a "Cronograma"
3. Selecciona un recurso
4. Selecciona la semana
5. Ve la disponibilidad en la tabla
6. Clic en celda disponible o va a "Crear Reserva"
7. Completa el formulario (Día, Hora, Asignatura, Docente, Recurso)
8. Clic en "Crear Reserva"
9. Ve mensaje de éxito
10. La reserva aparece automáticamente en el cronograma

### Admin revisa auditoría:
1. Inicia sesión como admin
2. Va a "Auditoría de Reservas"
3. Ve todas las reservas (activas y eliminadas)
4. Las eliminadas aparecen en rojo
5. Puede ver estadísticas y fechas de eliminación

---

## ✅ RESUMEN

El sistema permite:
- ✅ Reservar recursos educativos de forma organizada
- ✅ Ver disponibilidad en tiempo real
- ✅ Prevenir conflictos de horarios
- ✅ Mantener historial completo para auditoría
- ✅ Gestionar recursos y usuarios
- ✅ Exportar datos para reportes

**Todo esto con una interfaz intuitiva y actualización en tiempo real.**

