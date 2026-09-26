# Plataforma Web de Subastas de Vehiculos

Aplicacion web para explorar vehiculos, participar en subastas y recibir cambios de pujas en tiempo real. SQL Server es la fuente persistente y el backend valida las reglas criticas de oferta.

## Funcionalidades

- Registro y login con contrasenas bcrypt.
- Inventario, filtros por marca y nivel de dano, ficha tecnica y galeria de 5 imagenes por vehiculo demo.
- Subastas con monto base, validacion SQL del incremento minimo y fechas de inicio/cierre.
- Actualizacion en tiempo real mediante Socket.IO, rooms por subasta, temporizador y estados de oferta ganadora/superada.
- Postores anonimos en la interfaz.
- Pendiente: publicacion de vehiculos, mis publicaciones y edicion de publicaciones propias.

## Tecnologias

- React y Vite
- Node.js, Express y Socket.IO
- SQL Server
- `mssql` con Tedious para SQL Server remoto
- `msnodesqlv8` para SQL Server LocalDB

## Arquitectura

El frontend React consume la API REST de Express. Express y Socket.IO comparten el mismo servidor HTTP. El backend se conecta a SQL Server y ejecuta `PlaceBid` para validar las pujas de manera transaccional.

## Instalacion local

```powershell
npm install
Copy-Item .env.example .env
npm run start
```

Para LocalDB, configure `DB_DRIVER=msnodesqlv8`, `DB_DATABASE=SubastasVehiculosDB` y deje `DB_TABLE_PREFIX` vacio. Para SQL remoto, use `DB_DRIVER=tedious`, `DB_DATABASE=db_WebDevUMG` y `DB_TABLE_PREFIX=Keily_Subasta_`.

## Variables de entorno

Use `.env.example` como referencia. Nunca suba `.env`.

```env
DB_DRIVER=msnodesqlv8
DB_SERVER=(localdb)\\MSSQLLocalDB
DB_DATABASE=SubastasVehiculosDB
DB_USER=
DB_PASSWORD=
DB_PORT=1433
DB_ENCRYPT=false
DB_TRUST_SERVER_CERTIFICATE=true
DB_TABLE_PREFIX=
JWT_SECRET=replace-this-with-a-long-random-secret
PORT=3001
FRONTEND_URL=http://localhost:5173
VITE_API_URL=http://localhost:3001
```

## Usuarios de prueba

Usuarios exclusivamente DEMO:

| Nombre | Correo | Contrasena |
| --- | --- | --- |
| Ana | ana@demo.subastas | Demo123! |
| Bruno | bruno@demo.subastas | Demo123! |
| Carla | carla@demo.subastas | Demo123! |

## Prueba de tiempo real

1. Abra tres navegadores o ventanas de incognito.
2. Inicie sesion con Ana, Bruno y Carla.
3. Abra la misma subasta activa en los tres clientes.
4. Realice una puja valida.
5. Compruebe el nuevo monto, el estado Ganando/Superado y el temporizador sin usar F5.

## Sitio publicado

PENDIENTE DE DESPLIEGUE
