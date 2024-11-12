ARG FAIL2BAN_VERSION=1.1.0
ARG DEBIAN_VERSION=12-slim


# Only used to notify upstream image updates
FROM crazymax/fail2ban:1.1.0


FROM debian:${DEBIAN_VERSION} AS fail2ban-src

ARG FAIL2BAN_VERSION

RUN apt-get update \
  && apt-get install -y wget unzip \
  && wget -T 15 -t 10 "https://github.com/fail2ban/fail2ban/archive/${FAIL2BAN_VERSION}.zip" -O "/tmp/fail2ban-${FAIL2BAN_VERSION}.zip" \
  && unzip -d "/tmp" "/tmp/fail2ban-${FAIL2BAN_VERSION}.zip" \
  && mv "/tmp/fail2ban-${FAIL2BAN_VERSION}" "/tmp/fail2ban"


FROM debian:${DEBIAN_VERSION}

RUN --mount=from=fail2ban-src,source=/tmp/fail2ban,target=/tmp/fail2ban,rw \
  apt-get update \
  && apt-get install -y --no-install-recommends \
    bash \
    curl \
    grep \
    ipset \
    iptables \
    kmod \
    nftables \
    openssh-client \
    python3 \
    python3-dev \
    python3-dnspython \
    python3-inotify \
    python3-pip \
    python3-setuptools \
    python3-systemd \
    ssmtp \
    tzdata \
    wget \
    whois \
  && cd /tmp/fail2ban \
  && python3 setup.py install --without-tests \
  && apt-get remove -y --purge python3-dev python3-pip python3-setuptools \
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /etc/fail2ban/jail.d /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh

ENV TZ="UTC"

VOLUME [ "/data" ]

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "fail2ban-server", "-f", "-x", "-v", "start" ]

HEALTHCHECK --interval=10s --timeout=5s \
  CMD fail2ban-client ping || exit 1
