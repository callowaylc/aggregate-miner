export PORT_NGINX ?= 8080
export PORT_VARNISH ?= 80
export PORT_DATADOG ?= 8125
export KEY_COINHIVE ?= qvqJHHQ8CTQXKT4bsSszNbs6fSpnma5D

-include .secrets

.PHONY: release
release:
	@- docker-compose down -v 2>/dev/null
	@ docker-compose up -d --remove-orphans --force-recreate \
			nginx varnish
	@ docker-compose exec -d varnish \
			varnishncsa \
				-D \
				-a \
				-w /var/log/varnish/access.log

	@ sleep 5
	@ curl -Is localhost
	#@ docker-compose exec loggly ./add /var/log/varnish/access.log

.PHONY: build
build:
	@ docker-compose build datadog_metrics

.PHONY: stats
stats:
	# sends stats to datadog
	#@ docker-compose up -d --remove-orphans --force-recreate datadog_metrics
	curl -s https://api.coinhive.com/stats/site?secret=$(COINHIVE_SECRET) \
		| jq .hashesPerSecond \
		| xargs -I{} \
				echo -n "hashes_per_second:{}|g|#aggregrate-miner" >/dev/udp/localhost/8125