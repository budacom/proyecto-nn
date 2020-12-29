PROJECT ?= bandiera
LOGS_SINCE := 3h

SHELL := /bin/bash
REQUIRED_BINS := docker docker-compose gem docker-sync

run: help

BOLD ?= $(shell tput bold)
NORMAL ?= $(shell tput sgr0)

help:
	@echo "${BOLD}Local environment tasks:${NORMAL}"
	@echo "  setup				Setup the environment, create containers and initialize app"
	@echo "  destroy			Clean the environment, remove volumes, containers and images"
	@echo "  shell				Run bash interactive shell on the app container"
	@echo ""
	@echo "  syntax: make <task>"

setup: check
	@echo ""
	@echo "Getting images from registry.."
	docker-compose pull

	@echo ""
	@echo "Preparing network.."
	docker network inspect budadev >/dev/null 2>&1 || docker network create budadev

	@echo ""
	@echo "Initializating database.."

	@echo ""
	docker-compose up -d mysql; \
	echo "Waiting for mysql...";\
	( docker-compose logs -f mysql & ) | grep -q " mysqld: ready for connections";

	@echo ""
	@echo "Preparing application.."
	docker-compose build app
	COMPOSE_HTTP_TIMEOUT=360 \
		docker-compose run --rm app bundle exec rake db:migrate

	@echo ""
	@echo "All done. Go back to the README.md"

shell:
	docker-compose run --rm app sh

destroy: check confirm
	docker-compose down --volumes
	docker rmi -f $(PROJECT)-dev:latest >/dev/null 2>&1

confirm:
	@echo WARNING:
	@echo This command will remove all volumes from the containers, you will need to \
	setup you local environment from scratch.
	@echo ""
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]

check:
	$(foreach bin,$(REQUIRED_BINS),\
	$(if $(shell command -v $(bin) 2> /dev/null),,$(error Please install `$(bin)`)))