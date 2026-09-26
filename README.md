# 🚗 Plataforma Web de Subastas de Vehículos en Tiempo Real

Plataforma web tipo Copart para registrarse, iniciar sesión, publicar y buscar vehículos, filtrar el inventario y participar en subastas. Las pujas y sus estados se actualizan en tiempo real, sin necesidad de recargar la página con F5.

## 🌐 Enlaces del Proyecto

| Recurso | Enlace |
| --- | --- |
| **Sitio funcionando** | https://desarrollowebparcial2.netlify.app/ |
| **Backend / API** | https://desarrollo-web-parcial2-api.onrender.com |
| **Repositorio GitHub** | https://github.com/orem6/Desarrollo_web_parcial2.git |

## 👥 Usuarios de Prueba

Estas son credenciales **DEMO** destinadas a pruebas académicas.

| Usuario | Correo | Contraseña |
| --- | --- | --- |
| Ana | ana@demo.subastas | Demo123! |
| Bruno | bruno@demo.subastas | Demo123! |
| Carla | carla@demo.subastas | Demo123! |

## ✨ Funcionalidades

- Registro de usuarios e inicio de sesión.
- Bloqueo de usuarios anónimos para publicar vehículos y realizar pujas.
- Publicación de vehículos y edición de publicaciones propias.
- Galería con un mínimo de 5 imágenes y carrusel interactivo.
- Inventario dinámico con búsqueda de vehículos.
- Filtros por año, marca, modelo, combustible y nivel de daño.
- Clasificación visual de daño: verde, amarillo y rojo.
- Subastas en tiempo real mediante Socket.IO, sin F5.
- Validación del monto base e incremento mínimo del 10% en las subastas de producción.
- Temporizador de cierre de subasta.
- Indicador **"¡Vas ganando esta subasta!"** para la oferta más alta.
- Indicador **"Tu oferta ha sido superada"** cuando otro usuario mejora la puja.
- Postores mostrados de forma anónima en la interfaz.

## 🛠 Tecnologías

| Área | Tecnologías |
| --- | --- |
| Frontend | React, Vite, Socket.IO Client |
| Backend | Node.js, Express, Socket.IO |
| Base de datos | SQL Server, `mssql`, Tedious, `msnodesqlv8` |
| Seguridad | JWT, bcrypt |
| Hosting | Netlify, Render |

## 🏗 Arquitectura

```text
Frontend React / Netlify
        ↓
API REST + Socket.IO / Render
        ↓
SQL Server
db_WebDevUMG
        ↓
Keily_Subasta_*
```

- La API REST maneja autenticación, inventario, publicaciones y operaciones de puja.
- Socket.IO comunica las actualizaciones de las pujas en vivo a quienes están en la misma subasta.
- SQL Server persiste usuarios, vehículos, imágenes, subastas y ofertas.

## 🧪 Cómo Probar el Tiempo Real

1. Abrir el sitio: https://desarrollowebparcial2.netlify.app/
2. Abrir tres navegadores distintos o ventanas incógnito.
3. Iniciar sesión con Ana, Bruno y Carla.
4. Entrar a la misma subasta activa.
5. Realizar una puja con uno de los usuarios.
6. Verificar que el monto cambie sin F5, aparezca **"¡Vas ganando esta subasta!"** para el postor líder y el usuario anterior vea **"Tu oferta ha sido superada"**.

## 📦 Instalación Local

### Requisitos

- Node.js y npm.
- Una instancia de SQL Server configurada mediante las variables de entorno.

### Instalar dependencias

```powershell
npm install
Copy-Item .env.example .env
```

Configure `.env` con los valores de su entorno local antes de iniciar la aplicación. No suba este archivo al repositorio.

### Ejecutar frontend y backend

```powershell
# Frontend (Vite)
npm run dev

# Backend (Express + Socket.IO), en otra terminal
npm run server
```

También puede iniciar ambos servicios a la vez:

```powershell
npm start
```

### Generar build de frontend

```powershell
npm run build
```

## 🔐 Variables de Entorno

Defina estas variables en `.env`. Se muestran únicamente sus nombres; no incluya credenciales ni secretos en el repositorio.

```env
DB_DRIVER
DB_SERVER
DB_DATABASE
DB_USER
DB_PASSWORD
DB_PORT
DB_ENCRYPT
DB_TRUST_SERVER_CERTIFICATE
DB_TABLE_PREFIX
JWT_SECRET
PORT
FRONTEND_URL
VITE_API_URL
```

## 📌 Datos Importantes

- **Frontend:** https://desarrollowebparcial2.netlify.app/
- **Backend:** https://desarrollo-web-parcial2-api.onrender.com
- **GitHub:** https://github.com/orem6/Desarrollo_web_parcial2.git
