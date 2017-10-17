FROM ubuntu:16.04

WORKDIR /opt/datadog_metrics
RUN true && \
  apt update -y && \
  apt install -y \
    make \
    curl \
    cron \
    netcat \
    jq && \
  touch /var/log/cron.log

COPY ./src/etc/cron.d/export-metrics /etc/cron.d
COPY . .

CMD cron && tail -f /var/log/cron.log
