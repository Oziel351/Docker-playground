A production-ready Docker Compose setup for a modern web application with React frontend, Node.js backend, PostgreSQL database, and Redis cache.

## Architecture

## Services

### Frontend

- **Image**: Built from `./frontend/Dockerfile`
- **Port**: `8080:80`
- **Network**: `web`
- **Dependencies**: Waits for `backend` to be healthy

### Backend

- **Image**: Built from `./backend/Dockerfile`
- **Port**: `4000:4000`
- **Networks**: `web` (public) + `internal` (to access db/cache)
- **Dependencies**: Both `db` and `cache` must be healthy before starting
- **Restart Policy**: On failure, max 3 retries
- **Healthcheck**: GET `/api/health` every 15 seconds
- **Environment**: Loads from `.env` file

### PostgreSQL Database

- **Image**: `postgres:16-alpine`
- **Port**: Not exposed (internal only)
- **Network**: `internal`
- **Database**: `tienda`
- **Persistence**: Named volume `pg-data`
- **Healthcheck**: `pg_isready` every 10 seconds

### Redis Cache

- **Image**: `redis:7.0-alpine`
- **Port**: Not exposed (internal only)
- **Network**: `internal`
- **Persistence**: Named volume `redis-data`
- **Healthcheck**: `redis-cli ping` every 10 seconds

## Networks

- **`web`** (bridge): Frontend and backend communicate here. Backend is publicly accessible on port 4000.
- **`internal`** (bridge): Backend, database, and cache communicate here. Not accessible from the host.

## Volumes

- **`pg-data`**: Persists PostgreSQL data
- **`redis-data`**: Persists Redis snapshot

## Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+

### Setup

1. Clone the repository:

```bash
git clone <repo-url>
cd docker-fullstack
```

2. Create `.env` from the example:

```bash
cp .env.example .env
```

3. Build and start all services:

```bash
docker compose up --build
```

4. Verify services are healthy:

```bash
docker compose ps
```

Expected output:

5. Access the application:

- **Frontend**: http://localhost:8080
- **Backend API**: http://localhost:4000
- **API Health**: http://localhost:4000/api/health

### Stop Services

```bash
docker compose down
```

To also remove volumes and data:

```bash
docker compose down -v
```

## Environment Variables

See `.env.example` for all available configuration options. Copy and customize for your environment.

Critical variables:

- `DB_HOST`: Should be `db` (service name in Docker network)
- `REDIS_HOST`: Should be `cache` (service name)
- `NODE_ENV`: Should be `production` for backend

## Troubleshooting

### Services keep restarting

Check backend logs:

```bash
docker compose logs -f backend
```

### Can't connect to database from backend

Ensure `.env` has `DB_HOST=db` (not `localhost`). Localhost inside a container refers to that container itself, not the `db` service.

### Port already in use

Change the port mapping in `docker-compose.yml`:

```yaml
ports:
  - "8081:80" # Changed from 8080 to 8081
```

### Check service health details

```bash
docker compose ps
docker inspect <service_name>
docker logs <service_name>
```

## Development

### Rebuild after code changes

```bash
docker compose up --build
```

### Access container shell (if running)

```bash
docker compose exec backend sh
docker compose exec frontend sh
```

### View real-time logs

```bash
docker compose logs -f  # All services
docker compose logs -f backend  # Specific service
```

### Monitor resource usage

```bash
docker stats
```

## Production Considerations

- [ ] Move all secrets to a secrets manager (AWS Secrets Manager, HashiCorp Vault, etc.)
- [ ] Use `docker compose.prod.yml` with resource limits
- [ ] Enable PostgreSQL backups and replication
- [ ] Use Alpine-based images for smaller attack surface
- [ ] Run containers as non-root users (already done)

## Key Learnings

### Multi-network Architecture

- `web` network allows frontend-to-backend communication
- `internal` network isolates database and cache from the host
- Backend bridges both networks

### Health Checks

All services include healthchecks to ensure:

- Service is actually ready (not just running)
- Orchestrators can restart failed services
- `depends_on: condition: service_healthy` works correctly

### Layer Caching

- Dependencies (`package*.json`) copied before source code
- Rebuilds only recompile changed layers
- Reduces build time and image size

### Security

- No hardcoded secrets in Dockerfile or compose
- Secrets passed via `.env` file (not committed to git)
- Database not exposed to host
- Non-root user for backend (if configured in Dockerfile)

## License

MIT
