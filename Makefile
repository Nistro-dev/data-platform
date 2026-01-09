.PHONY: init secrets up down logs status clean

STACK_NAME = data_platform

# Initialiser Docker Swarm
init:
	docker swarm init || true

# Creer les secrets
secrets:
	echo "bateau" | docker secret create postgres_password - || true
	echo "bateau" | docker secret create minio_access_key - || true
	echo "bateau" | docker secret create minio_secret_key - || true

# Demarrer la stack
up: init secrets
	docker stack deploy -c docker-compose.yml $(STACK_NAME)

# Arreter la stack
down:
	docker stack rm $(STACK_NAME)

# Voir les logs d'un service
logs:
	docker service logs $(STACK_NAME)_$(SERVICE) -f

# Voir le statut des services
status:
	docker stack services $(STACK_NAME)

# Nettoyer tout
clean: down
	sleep 5
	docker volume prune -f
	docker secret rm postgres_password minio_access_key minio_secret_key || true
	docker swarm leave --force || true
