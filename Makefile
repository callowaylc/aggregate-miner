export PORT_NGINX ?= 8080
export PORT_VARNISH ?= 80
export PORT_DATADOG ?= 8125
export KEY_COINHIVE ?= qvqJHHQ8CTQXKT4bsSszNbs6fSpnma5D

-include .secrets


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
				-F '%{X-Forwarded-For}i %l %u %t "%r" %s %b "%{Referer}i" "%{User-agent}i"' \
				-D \
				-a \
				-w /var/log/varnish/access.log

	@ sleep 5
	@ curl -Is localhost 2>&1 >/dev/null
	@ docker-compose exec loggly ./add /var/log/varnish/access.log varnish-access
	@ docker-compose exec loggly ./add /var/log/nginx/ag.access.log nginx-access
	@ docker-compose exec loggly ./add /var/log/nginx/ag.error.log nginx-error

.PHONY: stats
stats:
	# sends stats to datadog
	@ ./bin/export-datadog-hashes-per-second

.PHONY: test
test:
	@ docker-compose exec loggly ./add /var/log/varnish/access.log varnish-access
