# DevOps Assignment — Starter API

A Node.js and Express API with PostgreSQL, containerized using Docker and Docker Compose.

## What's Included

- `Dockerfile` — Builds the API image.
- `docker-compose.yml` — Runs the API and PostgreSQL.
- `.github/workflows/ci.yml` — Builds, tests, and publishes the Docker image.
- `scripts/ops.sh` — Provides commands to manage and test the application.

## Prerequisites

- Docker Desktop or Docker Engine
- Docker Compose
- Bash (WSL2 Ubuntu on Windows)

## Run the Application

Start the application:

```bash
docker compose up -d --build
```

Check service status:

```bash
docker compose ps
```

Check API health:

```bash
curl http://localhost:8080/health
```

## Operations Script

Run these commands from the project root:

```bash
./scripts/ops.sh up
./scripts/ops.sh status
./scripts/ops.sh logs
./scripts/ops.sh smoke
./scripts/ops.sh down
```

## API Endpoints

| Method | Endpoint                   | Description                   |
| ------ | -------------------------- | ----------------------------- |
| GET    | `/health`                  | Check API and database health |
| GET    | `/users`                   | List users                    |
| POST   | `/users`                   | Create a user                 |
| GET    | `/notifications?user_id=1` | List user notifications       |
| POST   | `/notifications`           | Create a notification         |

## CI/CD

GitHub Actions runs on pull requests and pushes to `main`. It builds the API image, starts the services, runs smoke tests, and cleans up the test environment.

On successful pushes to `main`, the workflow publishes the API image to GitHub Container Registry (GHCR), tagged with `latest` and the full commit SHA.

## Database

PostgreSQL data is stored in a named Docker volume and persists when the stack is stopped with `docker compose down`.

The default database password is for local assignment testing only. Do not use it in production.
