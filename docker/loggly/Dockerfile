FROM ubuntu:16.04
ENV TZ=America/New_York

WORKDIR /opt/loggly
RUN true && \
  apt update -y && \
  apt install -y \
    tzdata \
    lsb-release \
    sudo \
    iputils-ping \
    wget \
    curl \
    rsyslog-gnutls && \
    cp -vf /usr/share/zoneinfo/${TZ} /etc/localtime && \
    curl -O https://www.loggly.com/install/configure-linux.sh && \
    curl -O https://www.loggly.com/install/configure-file-monitoring.sh && \
    sed -i "s/checkIfLogsMadeToLoggly$/echo \"Not checking...\"/g" configure-linux.sh && \
    sed -i "s/checkIfFileLogsMadeToLoggly$//g" configure-file-monitoring.sh && \
    sed -i "s/curl .*//g" configure-file-monitoring.sh && \
    service rsyslog start

COPY ./src/opt/loggly/add /opt/loggly
