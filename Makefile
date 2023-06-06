# run commands via docker-compose


### ENV VARS ###

# defaults
DOCKER_COMPOSE=docker-compose

# expose UID/GID as Makefile vars
GID := $(shell id -g)
UID := $(shell id -u)

# override with .env
ifneq (,$(wildcard ./.env))
	include .env
	export
endif


### DEFAULT RULE ###

.DEFAULT_GOAL := help
help: ## list all make targets
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


### COMMANDS ###

php-version: ## run php --version within container
	$(DOCKER_COMPOSE) exec wordpress php --version


### HELPER COMMANDS ###

docker-compose-build: ## run docker-compose build
	$(DOCKER_COMPOSE) build --build-arg "BASE_IMAGE=${BASE_IMAGE}"

docker-compose-down: ## run docker-compose down
	$(DOCKER_COMPOSE) down

docker-compose-up: ## run docker-compose up
	$(DOCKER_COMPOSE) up

shell-wordpress: ## run shell for debugging wordpress-db
	$(DOCKER_COMPOSE) exec wordpress sh

shell-wordpress-db: ## run shell for debugging wordpress-db
	$(DOCKER_COMPOSE) exec wordpress-db sh
