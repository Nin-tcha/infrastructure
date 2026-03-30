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

start:
	@echo "Lance chaque commande dans un terminal séparé :"
	@echo ""
	@echo "  make dev-auth"
	@echo "  make dev-player"
	@echo "  make dev-monster"
	@echo "  make dev-invoc"
	@echo "  make dev-fight"
	@echo "  make dev-stamina"

stop:
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
