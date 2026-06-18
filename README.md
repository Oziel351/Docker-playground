# Docker Multi-Stage Full-Stack Stack

[![Build and Push Docker Images](https://github.com/Oziel351/Docker-playground/actions/workflows/docker-deploy.yml/badge.svg)](https://github.com/Oziel351/Docker-playground/actions/workflows/docker-deploy.yml)

Practice project focused on Docker skills: multi-stage builds, networking,
health checks, named volumes, and secrets management using a React + Node.js

- PostgreSQL + Redis stack.

> **Purpose:** This is not a production application. The goal is to demonstrate
> Docker best practices using a minimal but realistic multi-service setup.

---

## Stack

| Service  | Image                                 | Role        |
| -------- | ------------------------------------- | ----------- |
| Frontend | Vite + React → served by Nginx alpine | Static SPA  |
| Backend  | Node.js 20 alpine                     | REST API    |
| Database | PostgreSQL 16 alpine                  | Persistence |
| Cache    | Redis 7 alpine                        | Cache layer |

---

## Architecture

You can find the architecture diagram in `/docs/architecture.png`. The key points are:

- The frontend and backend are on the `web` network, allowing them to communicate via service names (`backend`).
- The backend, database, and cache are on the `internal` network, isolating them from the host and frontend. The backend can access `db` and `cache` via their service names, but the frontend cannot.
- The database and cache use named volumes for data persistence, ensuring data survives container restarts and recreations.

---

## Key Docker Concepts Practiced

### Multi-stage Builds

Both `frontend` and `backend` use two-stage Dockerfiles:

- **Stage 1 (builder):** installs all dependencies and compiles
- **Stage 2 (runner):** copies only the compiled output, leaving build tools behind

Result: significantly smaller and more secure final images.

### Layer Caching

Dependencies (`package.json`, `pnpm-lock.yaml`) are copied before source code in every Dockerfile, so `pnpm install` only re-runs when dependencies actually change, not on every code change.

### Networks

Two isolated networks with a clear purpose:

- **`web`** (bridge): frontend ↔ backend communication
- **`internal`** (bridge): backend ↔ db ↔ cache communication

Database and cache are unreachable from the host — no `ports` exposed.

### Health Checks

Every service declares a `healthcheck`. The backend and frontend use `wget` (available in alpine without extra installs) to hit their respective endpoints. `depends_on` uses `condition: service_healthy` so services wait until dependencies are actually ready, not just started.

### Named Volumes

- `pg-data` → persists PostgreSQL data at `/var/lib/postgresql/data`
- `redis-data` → persists Redis snapshots at `/data`

Both volumes survive `docker compose down`. Data is only removed with `docker compose down -v`.

### Secrets Management

No passwords or keys are hardcoded in `docker-compose.yml` or any Dockerfile. All sensitive values are injected at runtime via `.env` (loaded by the backend service with `env_file`).

### Non-root User

The backend runs as the built-in `node` user from the official Node.js alpine image. Files are copied with `--chown=node:node` so the process can read them without needing root privileges.

## Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- pnpm (only if running outside Docker)

### Run

```bash
# 1. Clone
git clone https://github.com/tu-usuario/docker-fullstack.git
cd docker-fullstack

# 2. Set up environment
cp .env.example .env

# 3. Build and start
docker compose up --build

# 4. Verify all services are healthy
docker compose ps
```

### Verify

```bash
# Backend health
curl http://localhost:4000/api/health
# Expected: {"status":"ok","timestamp":"..."}

# Frontend
open http://localhost:8080
# Expected: Vite + React default page
```

### Stop

```bash
docker compose down          # stop, keep volumes
docker compose down -v       # stop and remove volumes
```

---

## Useful Commands

```bash
# Real-time logs for all services
docker compose logs -f

# Logs for a specific service
docker compose logs -f backend

# Real-time resource usage
docker stats

# Inspect a container (ports, health, env, mounts)
docker inspect backend_prueba

# Enter a running container
docker compose exec backend sh
docker compose exec frontend sh

# Rebuild only one service
docker compose up --build backend

## Problems I Hit and How I Fixed Them

#1 Getting role "root" does not exist when backend tries to connect to PostgreSQL
**Symptom:** Backend logs show `psql: error: FATAL:  role "root" does not exist`.
**Root cause:** The backend was trying to connect to PostgreSQL using the default `root` user, which doesn't exist in the PostgreSQL image.
**Fix:** Set the correct environment variables in the `.env` file and ensure they are passed to the backend service via `env_file` in `docker-compose.yml`. The backend should use `POSTGRES_USER` and `POSTGRES_PASSWORD` to connect.

#Screenshot: /docs/screenshots/postgres-root-error.png



Each issue above was discovered by running `docker compose logs -f` and `docker inspect` to read exit codes, error messages, and container state. Screenshots are included in `/docs/screenshots/` for reference.

---

## License

MIT
```
