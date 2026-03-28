build:
	mvn clean install -DskipTests

infra-up:
	docker compose up -d postgres kafka kafka-ui

infra-down:
	docker compose down

infra-logs:
	docker compose logs -f

dev-auth:
	cd services/auth-service && mvn quarkus:dev -Dquarkus.http.port=8081 -Ddebug=5005

dev-player:
	cd services/player-service && mvn quarkus:dev -Dquarkus.http.port=8082 -Ddebug=5006

dev-monster:
	cd services/monster-service && mvn quarkus:dev -Dquarkus.http.port=8083 -Ddebug=5007

dev-invoc:
	cd services/invocation-service && mvn quarkus:dev -Dquarkus.http.port=8084 -Ddebug=5008

dev-fight:
	cd services/fight-service && mvn quarkus:dev -Dquarkus.http.port=8085 -Ddebug=5009

dev-stamina:
	cd services/stamina-service && mvn quarkus:dev -Dquarkus.http.port=8086 -Ddebug=5010

SESSION := gatcha-dev

start:
	@echo "Démarrage de l'environnement Gatcha dans tmux..."

	tmux new-session -d -s $(SESSION) -n 'Infra'
	tmux send-keys -t $(SESSION):Infra 'make infra-up' C-m

	tmux new-window -t $(SESSION) -n 'Runners'

	tmux send-keys -t $(SESSION):Runners 'cd services/auth-service && mvn quarkus:dev' C-m

	tmux split-window -h -t $(SESSION):Runners
	tmux send-keys -t $(SESSION):Runners 'cd services/player-service && mvn quarkus:dev' C-m

	tmux split-window -h -t $(SESSION):Runners
	tmux send-keys -t $(SESSION):Runners 'cd services/monster-service && mvn quarkus:dev' C-m

	tmux split-window -v -t $(SESSION):Runners
	tmux send-keys -t $(SESSION):Runners 'cd services/invocation-service && mvn quarkus:dev' C-m

	tmux split-window -h -t $(SESSION):Runners
	tmux send-keys -t $(SESSION):Runners 'cd services/fight-service && mvn quarkus:dev' C-m

	tmux split-window -v -t $(SESSION):Runners
	tmux send-keys -t $(SESSION):Runners 'cd services/stamina-service && mvn quarkus:dev' C-m

	tmux select-layout -t $(SESSION):Runners tiled

	tmux new-window -t $(SESSION) -n 'Terminals'

	tmux send-keys -t $(SESSION):Terminals 'cd services/auth-service' C-m

	tmux split-window -h -t $(SESSION):Terminals
	tmux send-keys -t $(SESSION):Terminals 'cd services/player-service' C-m

	tmux split-window -h -t $(SESSION):Terminals
	tmux send-keys -t $(SESSION):Terminals 'cd services/monster-service' C-m

	tmux split-window -v -t $(SESSION):Terminals
	tmux send-keys -t $(SESSION):Terminals 'cd services/invocation-service' C-m

	tmux split-window -h -t $(SESSION):Terminals
	tmux send-keys -t $(SESSION):Terminals 'cd services/fight-service' C-m

	tmux split-window -v -t $(SESSION):Terminals
	tmux send-keys -t $(SESSION):Terminals 'cd services/stamina-service' C-m

	tmux select-layout -t $(SESSION):Terminals tiled

	tmux select-window -t $(SESSION):Runners
	tmux attach-session -t $(SESSION)

stop:
	@echo "Arrêt de l'environnement..."
	-tmux kill-session -t $(SESSION) 2>/dev/null
	make infra-down

test:
	mvn test -DskipTests=false -pl !services/e2e-tests

test-integration:
	mvn verify -DskipITs=false -pl !services/e2e-tests

test-e2e:
	@echo "Démarrage tests E2E"
	docker compose -f docker-compose.e2e.yaml up --build -d --remove-orphans
	@sleep 30
	cd services/e2e-tests && mvn test -Dtest=InvocationFlowE2ETest || (make docker-all-down && exit 1)
	docker compose -f docker-compose.e2e.yaml down
	@echo "Tests E2E terminés !"

# si environnement déjà lancé
test-e2e-only:
	cd services/e2e-tests && mvn test -Dtest=InvocationFlowE2ETest

docker-all:
	docker compose -f docker-compose.e2e.yaml up --build

docker-all-detached:
	docker compose -f docker-compose.e2e.yaml up --build -d

docker-all-down:
	docker compose -f docker-compose.e2e.yaml down

docker-all-logs:
	docker compose -f docker-compose.e2e.yaml logs -f
