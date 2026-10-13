# 🔧 Configurar Firestore - Guía Paso a Paso

## ⚠️ ERROR ACTUAL
Si ves: **"Missing or insufficient permissions"**, necesitas configurar las reglas de Firestore.

## 📋 PASOS RÁPIDOS (5 minutos)

### Paso 1: Abre Firebase Console
1. Ve a: **https://console.firebase.google.com/**
2. Inicia sesión con tu cuenta de Google
3. Selecciona el proyecto: **recursostic-18bb8**

### Paso 2: Ve a Firestore Database
1. En el menú lateral izquierdo, busca **"Firestore Database"**
2. Haz clic en **"Firestore Database"**
3. Si es la primera vez, haz clic en **"Crear base de datos"**
   - Selecciona modo: **"Modo de prueba"** (para desarrollo)
   - Ubicación: Elige la más cercana
   - Haz clic en **"Habilitar"**

### Paso 3: Configura las Reglas
1. En la pestaña superior, haz clic en **"Reglas"** (Rules)
2. Verás un editor de código con reglas por defecto
3. **BORRA TODO** el contenido del editor
4. Copia y pega UNA de estas opciones:

#### Opción A: Reglas Temporales (MÁS FÁCIL - Para desarrollo)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

#### Opción B: Reglas Completas (Con permisos diferenciados)
Copia el contenido completo del archivo `firestore.rules` de tu proyecto.

### Paso 4: Publica las Reglas
1. Haz clic en el botón **"Publicar"** (Publish) en la parte superior
2. Espera a que aparezca el mensaje: **"Reglas publicadas correctamente"**

### Paso 5: Prueba la Aplicación
1. Vuelve a tu aplicación Flutter
2. Haz clic en **"Ir al Login"**
3. Regístrate o inicia sesión
4. ✅ Debería funcionar sin errores de permisos

## 🎯 Verificación Rápida

Después de publicar las reglas:
- ✅ La aplicación debería cargar sin errores
- ✅ Podrás registrarte e iniciar sesión
- ✅ Podrás ver recursos y crear reservas

## 📝 Notas Importantes

- **Reglas Temporales**: Las reglas de la Opción A son más permisivas y funcionan inmediatamente
- **Reglas Completas**: Las reglas de la Opción B tienen permisos diferenciados por rol (docente/admin)
- **Tiempo de Propagación**: Las reglas pueden tardar unos segundos en aplicarse

## 🆘 Si Sigue Sin Funcionar

1. Verifica que hayas publicado las reglas (botón "Publicar")
2. Espera 1-2 minutos y vuelve a intentar
3. Verifica que el usuario esté autenticado correctamente
4. Revisa la consola de Firebase para ver si hay errores


