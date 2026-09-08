# syntax=docker/dockerfile:1

ARG FAIL2BAN_VERSION=1.1.0
ARG DEBIAN_VERSION=13-slim


# Only used to notify upstream image updates
FROM crazymax/fail2ban:1.1.0


FROM --platform=${BUILDPLATFORM} scratch AS fail2ban-src

ARG FAIL2BAN_VERSION

ADD "https://github.com/fail2ban/fail2ban.git#${FAIL2BAN_VERSION}" .


FROM debian:${DEBIAN_VERSION}

ARG DEBIAN_FRONTEND=noninteractive

# For the `jq` dependency, please refer to https://github.com/crazy-max/docker-fail2ban/issues/237
RUN --mount=from=fail2ban-src,target=/tmp/fail2ban,rw \
  apt-get update \
  && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    grep \
    inotify-tools \
    ipset \
    iptables \
    jq \
    kmod \
    mmdb-bin \
    nftables \
    openssh-client \
    python3 \
    python3-dev \
    python3-dnspython \
    python3-pyinotify \
    python3-setuptools \
    python3-systemd \
    tzdata \
    wget \
    whois \
  && cd /tmp/fail2ban \
  && python3 setup.py install --without-tests \
  && apt-get purge -y --auto-remove python3-dev \
  && apt-get clean \
  && rm -rf /etc/fail2ban/jail.d /root/.cache /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh

ENV TZ="UTC"

VOLUME [ "/data" ]

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "fail2ban-server", "-f", "-x", "-v", "start" ]

HEALTHCHECK --interval=10s --timeout=5s \
  CMD fail2ban-client ping || exit 1
