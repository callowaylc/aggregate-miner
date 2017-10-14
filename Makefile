export PORT_NGINX ?= 8080
export PORT_VARNISH ?= 80
export KEY_COINHIVE ?= qvqJHHQ8CTQXKT4bsSszNbs6fSpnma5D

.PHONY: release
release:
	@ docker-compose up -d --remove-orphans --force-recreate