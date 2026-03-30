# Nintcha

Jeu de gacha développé en microservices Java

Le but est de collecter des monstres, constituer des équipes, affronter d'autres joueurs et grimper dans le classement Elo !

## Architecture

![Topologie système](docs/compiled/Diagramme%20sans%20nom-System%20Topology.drawio.png)

Six services backend, chacun avec sa propre base de données. La communication inter-services passe par **Kafka**, la seule exception est **l'authentification**, qui reste synchrone : chaque service appelle auth-service en REST pour valider le token à chaque requête (voir [pourquoi kafka est utilisé ?](./docs/why-kafka.md))

| Service            | Port | Rôle                                           |
| ------------------ | ---- | ---------------------------------------------- |
| auth-service       | 8081 | Émission et validation de tokens *(synchrone)* |
| player-service     | 8082 | Profils, inventaire, gestion d'équipe          |
| monster-service    | 8083 | Catalogue et instances de monstres             |
| invocation-service | 8084 | Invocations gacha                              |
| fight-service       | 8085 | Combat PvP par équipe, Elo, classement         |
| stamina-service    | 8086 | Stamina, régénération, réclamations gratuites  |

## Démarrage rapide

```bash
git submodule update --init --recursive   # Initialiser les submodules après un clone

make build      # Compiler tous les services Java (obligatoire en premier)
make infra-up   # Démarrer PostgreSQL, Kafka, Kafka UI
make start      # Démarrer tous les services dans tmux

cd nintcha-front && npm install && npm run dev   # Frontend sur :3000
```

Services individuels (rechargement à chaud) :

```bash
make dev-auth
make dev-player
make dev-monster
make dev-invoc
make dev-fight
make dev-stamina
```

```bash
make stop        # Tuer la session tmux + arrêter l'infra
```

## Tests

```bash
make test                # Tests unitaires (~1 s)
make test-integration    # Tests d'intégration via Testcontainers (~1 min)
make test-e2e            # E2E complet : build + démarrage + test + arrêt (~5 min)
```

## Docker (stack complète)

```bash
make docker-all             # Build et démarrage de tout
make docker-all-detached    # Idem, en arrière-plan
make docker-all-down        # Arrêt
```

## URLs utiles

|                    | URL                                            |
| ------------------ | ---------------------------------------------- |
| Application        | http://localhost:3000                          |
| Kafka UI           | http://localhost:8090                          |
| Santé des services | `http://localhost:808x/q/health`               |
| PostgreSQL         | `localhost:5432` — `gatcha` / `gatchapassword` |
