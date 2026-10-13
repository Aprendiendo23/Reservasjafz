# 🚀 Ejecutar Configuración Automática

## ⚡ Método Rápido (Recomendado)

### Opción 1: Script de PowerShell (Windows)

1. **Abre PowerShell como Administrador:**
   - Presiona `Win + X`
   - Selecciona "Windows PowerShell (Administrador)" o "Terminal (Administrador)"

2. **Navega a la carpeta del proyecto:**
   ```powershell
   cd C:\Users\Antonio\Documents\reservas_recursos
   ```

3. **Ejecuta el script:**
   ```powershell
   .\configurar_firebase.ps1
   ```

4. **Sigue las instrucciones:**
   - Si Node.js no está instalado, el script lo instalará automáticamente
   - Se abrirá una ventana del navegador para iniciar sesión en Firebase
   - Selecciona el proyecto `recursostic-18bb8`
   - El script desplegará automáticamente las reglas e índices

### Opción 2: Script Batch (Windows - Más Simple)

1. **Haz doble clic en:** `configurar_firebase_simple.bat`
2. **Sigue las instrucciones en pantalla**

---

## 📋 Requisitos Previos

### Si no tienes Node.js:

El script intentará instalarlo automáticamente, pero si falla:

1. **Descarga Node.js:**
   - Ve a: https://nodejs.org/
   - Descarga la versión LTS (recomendada)
   - Instálalo con las opciones por defecto

2. **Reinicia PowerShell/Terminal**

3. **Ejecuta el script nuevamente**

---

## 🔧 Configuración Manual (Si los scripts fallan)

### 1. Instalar Firebase CLI manualmente:

```bash
npm install -g firebase-tools
```

### 2. Iniciar sesión:

```bash
firebase login
```

### 3. Configurar proyecto:

```bash
firebase use recursostic-18bb8 --add
```

### 4. Desplegar reglas e índices:

```bash
firebase deploy --only firestore
```

---

## ✅ Verificación

Después de ejecutar el script, verifica:

1. **Reglas:**
   - Ve a: https://console.firebase.google.com/project/recursostic-18bb8/firestore/rules
   - Deben estar publicadas sin errores

2. **Índices:**
   - Ve a: Firestore Database → Índices
   - Deben estar en estado "Building" o "Enabled"

3. **Usuario Admin:**
   - Crea manualmente un usuario con `rol: "admin"` (ver `INSTRUCCIONES_RAPIDAS.md`)

---

## 🐛 Solución de Problemas

### Error: "firebase no se reconoce"
- **Solución:** Instala Firebase CLI: `npm install -g firebase-tools`
- Reinicia PowerShell/Terminal

### Error: "node no se reconoce"
- **Solución:** Instala Node.js desde https://nodejs.org/
- Reinicia PowerShell/Terminal

### Error: "Permission denied"
- **Solución:** Ejecuta PowerShell como Administrador

### Error al iniciar sesión
- **Solución:** Asegúrate de tener una cuenta de Google vinculada a Firebase
- Verifica que tengas acceso al proyecto `recursostic-18bb8`

---

## 📝 Notas

- Los índices pueden tardar 2-5 minutos en crearse
- Después de desplegar reglas, espera 10-20 segundos
- El usuario administrador debe crearse manualmente desde Firebase Console

---

¡Listo! Una vez ejecutado el script, tu Firebase estará configurado. 🎉

