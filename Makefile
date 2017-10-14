export PORT_NGINX ?= 8080
export PORT_VARNISH ?= 80

.PHONY: release
release:
	@ docker-compose up -d --remove-orphans --force-recreate