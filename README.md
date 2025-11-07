# Fudo — Prueba Técnica

Instrucciones mínimas de configuración y uso del proyecto.

## Requisitos (Sin Docker)
- Ruby (3.x), Bundler
- PostgreSQL accesible según `config/database.yml`

## Instalación con Docker (Recomendado)

### Requisitos
- Docker
- Docker Compose

### Quick Start

1. Crear un archivo `.env` con los secretos:
```bash
JWT_SECRET=your_secure_jwt_secret_here
SESSION_SECRET=your_secure_session_secret_here
```

2. Construir y arrancar los contenedores:
```bash
docker-compose up --build
```

Los servicios estarán disponibles en:
- API: http://localhost:9292
- PostgreSQL: localhost:5432
- Redis: localhost:6379

### Estructura de Contenedores

La aplicación corre en cuatro contenedores:
- `api`: El servidor principal Cuba
- `sidekiq`: Procesador de trabajos en background
- `postgres`: Base de datos PostgreSQL
- `redis`: Redis para Sidekiq y blacklist de tokens

### Comandos Docker Útiles

Para desarrollo:
```bash
# Levantar todos los servicios
docker-compose up --build

# Ejecutar migraciones
docker-compose exec api rake db:migrate

# Ver estado de Sidekiq
docker-compose exec sidekiq sidekiq -r ./api/api.rb status

# Acceder a PostgreSQL
docker-compose exec postgres psql -U postgres fudo_production
```

### Troubleshooting Docker

Si los contenedores fallan al arrancar:
1. Revisar los logs: `docker-compose logs -f [nombre_servicio]`
2. Asegurar que los permisos del directorio de datos PostgreSQL son correctos
3. Verificar que todas las variables de entorno requeridas están configuradas

Para reiniciar el ambiente:
```bash
docker-compose down -v  # Advertencia: Esto borrará todos los datos
docker-compose up --build
```

## Instalación Manual (Sin Docker)

### Instalación de dependencias

```bash
bundle install
```

## Variables de entorno importantes
- `RACK_ENV` — entorno (por ejemplo `development`, `test`, `production`).
- `SESSION_SECRET` — secreto para las sesiones (usado por Rack::Session::Cookie).
- `JWT_SECRET` — secreto para firmar JWT.

## Base de datos
- Edita `config/database.yml` si necesitas cambiar host/usuario/contraseña. El fichero ya contiene configuraciones por entorno.
- La aplicación usa Sequel; la conexión se establece al cargar la app, antes de cargar los modelos (asegúrate de que `config/database.yml` existe y está correcto).

## Crear la base de datos y migraciones
- Hay una tarea Rake para preparar la DB (crear DB, ejecutar migraciones y crear un usuario admin). Ejemplo:

```bash
# Crear DB, migrar y crear usuario admin (usa RACK_ENV=development por defecto)
rake create

# Para usar el entorno de test
RACK_ENV=test rake create

# Cambiar credenciales por defecto con variables de entorno:
ADMIN_USER=admin_username ADMIN_PASSWORD=secreto rake create
```

## Pruebas
- RSpec está disponible en el grupo de desarrollo/test. Ejecuta:

```bash
bundle exec rspec
```

## Sidekiq / Redis (cola de jobs)
- Requisitos: Redis (local o remoto) y la gema `sidekiq` (ya está en el Gemfile).
- Levantar Redis:

```bash
# en background (Linux)
redis-server &
```

- Ejecutar Sidekiq (carga la app y registrará el middleware de normalización):

```bash
bundle exec sidekiq -r ./api/api.rb
```

## Levantar el servidor

```bash
# Usando rackup (puma por defecto en este proyecto)
bundle exec rackup -p 9292
```
