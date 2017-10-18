export PORT_NGINX ?= 8080
export PORT_VARNISH ?= 80
export PORT_DATADOG ?= 8125
export KEY_COINHIVE ?= qvqJHHQ8CTQXKT4bsSszNbs6fSpnma5D
export TZ ?= America/New_York

-include .secrets

.PHONY: all
all:
	mkdir -p ./build

.PHONY: build
build:
	@ docker pull nginx:1.13
	@ docker pull million12/varnish:latest
	@ docker-compose build loggly datadog_metrics

.PHONY: release
release:
	@- docker-compose down -v 2>/dev/null
	@ docker-compose up -d --remove-orphans --force-recreate \
			nginx varnish loggly datadog datadog_metrics
	@ docker-compose exec -d varnish \
			varnishncsa \
				-F '"%{X-Forwarded-For}i" %h %l %u %t "%r" %s %b "%{Referer}i" "%{User-agent}i"' \
				-D \
				-a \
				-w /var/log/varnish/access.log

	@ sleep 5
	@ curl -Is localhost 2>&1 >/dev/null
	@ curl -Is localhost:8080 2>&1 >/dev/null
	@ curl -Is localhost:8080/does-not-exist 2>&1 >/dev/null

	docker-compose exec loggly bash ./configure-linux.sh \
      -a callowayart \
      -t $(LOGGLY_TOKEN) \
      -u callowayart \
      -p $(LOGGLY_PASSWORD)
	sleep 2
	@ docker-compose exec loggly ./add /var/log/nginx/ag.error.log nginx-error
	@ docker-compose exec loggly ./add /var/log/varnish/access.log varnish-access
	@ docker-compose exec loggly ./add /var/log/nginx/ag.access.log nginx-access


.PHONY: stats
stats:
	# sends stats to datadog
	@ ./bin/export-datadog-hashes-per-second

.PHONY: test
test:
	@- docker-compose down -v 2>/dev/null
	@ docker-compose up -d --remove-orphans --force-recreate \
			loggly

