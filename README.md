# Nintcha

Gacha game built as Java microservices

Goal is to collect monsters, build teams, fight other players, climb the Elo leaderboard !

## Architecture

![System Topology](docs/compiled/Diagramme%20sans%20nom-System%20Topology.drawio.png)

Six backend services, each with its own database. Inter-service communication goes through **Kafka** - the only exception is **authentication**, which is synchronous: every service calls auth-service via REST to validate the token on each request (see details over [Why kafka ?](./docs/why-kafka.md))

| Service            | Port | Role                                        |
| ------------------ | ---- | ------------------------------------------- |
| auth-service       | 8081 | Token issuance & validation *(synchronous)* |
| player-service     | 8082 | Profiles, inventory, team management        |
| monster-service    | 8083 | Monster catalog & instances                 |
| invocation-service | 8084 | Gacha pulls                                 |
| fight-service       | 8085 | PvP team combat, Elo, leaderboard           |
| stamina-service    | 8086 | Stamina, regen, free claims                 |

## Quick Start

```bash
git submodule update --init --recursive   # Init submodules after a fresh clone

make build      # Build all Java services (required first)
make infra-up   # Start PostgreSQL, Kafka, Kafka UI
make start      # Start all services in tmux

cd nintcha-front && npm install && npm run dev   # Frontend on :3000
```

Individual services (hot reload):

```bash
make dev-auth
make dev-player
make dev-monster
make dev-invoc
make dev-fight
make dev-stamina
```

```bash
make stop        # Kill tmux session + bring down infra
```

## Testing

```bash
make test                # Unit tests (~1 s)
make test-integration    # Integration tests via Testcontainers (~1 min)
make test-e2e            # Full E2E: build + start + test + teardown (~5 min)
```

## Docker (full stack)

```bash
make docker-all             # Build and start everything
make docker-all-detached    # Same, detached
make docker-all-down        # Stop
```

## Useful URLs

|                | URL                                            |
| -------------- | ---------------------------------------------- |
| App            | http://localhost:3000                          |
| Kafka UI       | http://localhost:8090                          |
| Service health | `http://localhost:808x/q/health`               |
| PostgreSQL     | `localhost:5432` - `gatcha` / `gatchapassword` |
