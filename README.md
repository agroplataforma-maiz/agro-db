# Agroplataforma Digital - Entorno Docker
**PEE-2025-G-369 | TecNM Ciudad Valles**

## Estructura de archivos

```
proyecto/
├── docker-compose.yml       # Configuración de servicios
├── agroplataforma_bd.sql    # Script de base de datos
├── pgadmin_servers.json     # Conexión preconfigurada para pgAdmin
├── .env.example             # Plantilla de variables de entorno
├── .env                     # Variables reales (NO subir a Git)
├── .gitignore
└── backups/                 # Backups automáticos diarios
```

## Requisitos

- Docker >= 24.0
- Docker Compose >= 2.20
- 2 GB de RAM disponibles en el servidor

## Instalación (primera vez)

```bash
# 1. Clonar o copiar los archivos al servidor
# 2. Crear archivo de variables de entorno
cp .env.example .env

# 3. Editar .env con contraseñas seguras
nano .env

# 4. Crear carpeta de backups
mkdir -p backups

# 5. Levantar los servicios
docker compose up -d

# 6. Verificar que todo esté corriendo
docker compose ps
```

## Accesos

| Servicio   | URL                        | Usuario          |
|------------|----------------------------|------------------|
| pgAdmin    | http://localhost:8080       | admin@tecnm.mx   |
| PostgreSQL | localhost:5432              | agro_admin       |

> En servidor institucional, reemplazar `localhost` por la IP del servidor.

## Comandos útiles

```bash
# Ver estado de los servicios
docker compose ps

# Ver logs en tiempo real
docker compose logs -f db

# Detener sin borrar datos
docker compose down

# Backup manual inmediato
docker compose exec db pg_dump -U agro_admin agroplataforma > backups/backup_manual.sql

# Restaurar desde backup
docker compose exec -i db psql -U agro_admin agroplataforma < backups/backup_manual.sql

# Conectarse directamente a PostgreSQL
docker compose exec db psql -U agro_admin -d agroplataforma

# Reiniciar solo un servicio
docker compose restart db
```

## Backups automáticos

El servicio `backup` genera un respaldo diario automáticamente en la carpeta `backups/`.
Conserva los últimos **7 backups** y elimina los más antiguos.

## Notas para el equipo

- Los datos del campo se sincronizan desde KoboToolbox contra el servidor institucional en `5432`.
- Para acceso remoto desde laptops del equipo, abrir el puerto `5432` en el firewall del servidor TecNM.
- Las contraseñas del archivo `.env` **nunca** deben compartirse por correo ni subirse a Git.
