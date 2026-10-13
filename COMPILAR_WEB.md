# 🌐 Compilar y Desplegar Aplicación Web

## 📋 Compilar para Web

### 1. Compilar la Aplicación

Ejecuta el siguiente comando para compilar la aplicación web:

```bash
flutter build web --release
```

**Opciones adicionales:**
- `--web-renderer html` - Usa renderizador HTML (compatible con más navegadores)
- `--web-renderer canvaskit` - Usa CanvasKit (mejor rendimiento, archivo más grande)
- `--base-href /ruta/` - Si vas a desplegar en un subdirectorio

**Ejemplo completo:**
```bash
flutter build web --release --web-renderer html
```

### 2. Ubicación de los Archivos

Después de compilar, los archivos estarán en:

```
build/web/
├── index.html
├── main.dart.js
├── assets/
└── ... (otros archivos)
```

---

## 🚀 Opciones de Despliegue

### Opción 1: Firebase Hosting (Recomendado) ⭐

Firebase Hosting es ideal porque ya estás usando Firebase para tu base de datos.

#### Pasos:

1. **Instalar Firebase CLI** (si no lo tienes):
   ```bash
   npm install -g firebase-tools
   ```

2. **Iniciar sesión en Firebase**:
   ```bash
   firebase login
   ```

3. **Inicializar Firebase Hosting** (si no está configurado):
   ```bash
   firebase init hosting
   ```
   
   - Selecciona tu proyecto: `recursostic-18bb8`
   - Directorio público: `build/web`
   - Configurar como SPA (Single Page App): **Sí**
   - Configurar GitHub Actions: Opcional

4. **Desplegar**:
   ```bash
   flutter build web --release
   firebase deploy --only hosting
   ```

5. **Tu aplicación estará en**:
   ```
   https://recursostic-18bb8.web.app
   ```
   o
   ```
   https://recursostic-18bb8.firebaseapp.com
   ```

#### Configuración automática con Firebase:

Si ya tienes `firebase.json`, solo necesitas:

```bash
# Compilar
flutter build web --release

# Desplegar
firebase deploy --only hosting
```

---

### Opción 2: GitHub Pages

#### Pasos:

1. **Compilar con base-href**:
   ```bash
   flutter build web --release --base-href /nombre-repositorio/
   ```

2. **Subir a GitHub**:
   ```bash
   git add build/web
   git commit -m "Desplegar web"
   git push origin main
   ```

3. **Configurar GitHub Pages**:
   - Ve a tu repositorio en GitHub
   - Settings → Pages
   - Source: `gh-pages` branch o `/docs` folder
   - Selecciona la carpeta `build/web`

---

### Opción 3: Netlify

#### Pasos:

1. **Compilar**:
   ```bash
   flutter build web --release
   ```

2. **Arrastra y suelta** la carpeta `build/web` en [Netlify Drop](https://app.netlify.com/drop)

3. **O usa Netlify CLI**:
   ```bash
   npm install -g netlify-cli
   netlify deploy --prod --dir=build/web
   ```

---

### Opción 4: Vercel

#### Pasos:

1. **Instalar Vercel CLI**:
   ```bash
   npm install -g vercel
   ```

2. **Compilar y desplegar**:
   ```bash
   flutter build web --release
   vercel --prod build/web
   ```

---

### Opción 5: Servidor Web Propio (Apache/Nginx)

#### Pasos:

1. **Compilar**:
   ```bash
   flutter build web --release
   ```

2. **Subir archivos**:
   - Copia todo el contenido de `build/web/` a tu servidor
   - Asegúrate de que el servidor esté configurado para servir archivos estáticos

3. **Configurar Nginx** (ejemplo):
   ```nginx
   server {
       listen 80;
       server_name tu-dominio.com;
       root /ruta/a/build/web;
       index index.html;
       
       location / {
           try_files $uri $uri/ /index.html;
       }
   }
   ```

---

## ⚙️ Configuración Adicional

### Actualizar título y descripción

Edita `web/index.html`:

```html
<title>Sistema de Reservas de Recursos</title>
<meta name="description" content="Sistema para gestionar reservas de recursos TIC">
```

### Actualizar manifest.json

Edita `web/manifest.json` para personalizar:
- Nombre de la aplicación
- Colores del tema
- Iconos

### Configurar Firebase para Web

Asegúrate de que `firebase_options.dart` tenga la configuración web correcta.

---

## 🔧 Solución de Problemas

### Error: "Firebase not initialized"
- Verifica que `firebase_options.dart` tenga la configuración web
- Asegúrate de que Firebase esté inicializado en `main.dart`

### Error: "CORS"
- Si usas Firebase Hosting, esto se resuelve automáticamente
- Para otros servidores, configura CORS correctamente

### La aplicación no carga
- Verifica que todos los archivos estén en `build/web/`
- Revisa la consola del navegador para errores
- Asegúrate de que el servidor esté configurado para SPA (redirigir todas las rutas a `index.html`)

---

## 📝 Script Automático para Firebase Hosting

Crea un archivo `deploy_web.sh`:

```bash
#!/bin/bash
echo "Compilando aplicación web..."
flutter build web --release

echo "Desplegando a Firebase Hosting..."
firebase deploy --only hosting

echo "✅ Despliegue completado!"
echo "🌐 URL: https://recursostic-18bb8.web.app"
```

O para Windows, `deploy_web.bat`:

```batch
@echo off
echo Compilando aplicacion web...
flutter build web --release

echo Desplegando a Firebase Hosting...
firebase deploy --only hosting

echo Despliegue completado!
echo URL: https://recursostic-18bb8.web.app
pause
```

---

## 📊 Comparación de Opciones

| Opción | Gratis | Fácil | CDN | SSL | Recomendado |
|--------|--------|-------|-----|-----|-------------|
| Firebase Hosting | ✅ | ⭐⭐⭐ | ✅ | ✅ | ⭐⭐⭐ |
| GitHub Pages | ✅ | ⭐⭐ | ✅ | ✅ | ⭐⭐ |
| Netlify | ✅ | ⭐⭐⭐ | ✅ | ✅ | ⭐⭐⭐ |
| Vercel | ✅ | ⭐⭐⭐ | ✅ | ✅ | ⭐⭐⭐ |
| Servidor Propio | ❌ | ⭐ | ❌ | ⚠️ | ⭐ |

---

## 🎯 Recomendación

**Usa Firebase Hosting** porque:
- ✅ Ya estás usando Firebase
- ✅ Integración perfecta con Firestore
- ✅ SSL automático
- ✅ CDN global
- ✅ Fácil de configurar
- ✅ Gratis para proyectos pequeños
