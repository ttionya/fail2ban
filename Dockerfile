# syntax=docker/dockerfile:1

# See https://github.com/crazy-max/docker-fail2ban/blob/master/Dockerfile for more information.
FROM crazymax/fail2ban:1.1.1-debian

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends inotify-tools \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && echo "Execute: fail2ban-server --version" \
  && fail2ban-server --version \
  && echo "Execute: fail2ban-server --test" \
  && fail2ban-server --test

COPY --chmod=755 entrypoint-wrapper.sh /entrypoint-wrapper.sh
COPY --chmod=755 entrypoint2.sh /entrypoint2.sh

ENTRYPOINT [ "/entrypoint-wrapper.sh" ]
