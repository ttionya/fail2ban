#!/bin/bash

TZ=${TZ:-UTC}

F2B_LOG_TARGET=${F2B_LOG_TARGET:-STDOUT}
F2B_LOG_LEVEL=${F2B_LOG_LEVEL:-INFO}
F2B_DB_PURGE_AGE=${F2B_DB_PURGE_AGE:-1d}
IPTABLES_MODE=${IPTABLES_MODE:-auto}

SSMTP_PORT=${SSMTP_PORT:-25}
SSMTP_HOSTNAME=${SSMTP_HOSTNAME:-$(hostname -f)}
SSMTP_TLS=${SSMTP_TLS:-NO}
SSMTP_STARTTLS=${SSMTP_STARTTLS:-NO}

# From https://github.com/docker-library/mariadb/blob/master/docker-entrypoint.sh#L21-L41
# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"
  if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
    echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
    exit 1
  fi
  local val="$def"
  if [ "${!var:-}" ]; then
    val="${!var}"
  elif [ "${!fileVar:-}" ]; then
    val="$(< "${!fileVar}")"
  fi
  export "$var"="$val"
  unset "$fileVar"
}

# Timezone
echo "Setting timezone to ${TZ}..."
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

# SSMTP
file_env 'SSMTP_PASSWORD'
echo "Setting SSMTP configuration..."
if [ -z "$SSMTP_HOST" ] ; then
  echo "WARNING: SSMTP_HOST must be defined if you want fail2ban to send emails"
else
  cat > /etc/ssmtp/ssmtp.conf <<EOL
mailhub=${SSMTP_HOST}:${SSMTP_PORT}
hostname=${SSMTP_HOSTNAME}
FromLineOverride=YES
UseTLS=${SSMTP_TLS}
UseSTARTTLS=${SSMTP_STARTTLS}
EOL
  # Authentication to SMTP server is optional.
  if [ -n "$SSMTP_USER" ] ; then
    cat >> /etc/ssmtp/ssmtp.conf <<EOL
AuthUser=${SSMTP_USER}
AuthPass=${SSMTP_PASSWORD}
EOL
  fi
fi
unset SSMTP_HOST
unset SSMTP_USER
unset SSMTP_PASSWORD

# Init
echo "Initializing files and folders..."
mkdir -p /data/db /data/action.d /data/filter.d /data/jail.d
ln -sf /data/jail.d /etc/fail2ban/

# Fail2ban conf
echo "Setting Fail2ban configuration..."
sed -i "s|logtarget =.*|logtarget = $F2B_LOG_TARGET|g" /etc/fail2ban/fail2ban.conf
sed -i "s/loglevel =.*/loglevel = $F2B_LOG_LEVEL/g" /etc/fail2ban/fail2ban.conf
sed -i "s/dbfile =.*/dbfile = \/data\/db\/fail2ban\.sqlite3/g" /etc/fail2ban/fail2ban.conf
sed -i "s/dbpurgeage =.*/dbpurgeage = $F2B_DB_PURGE_AGE/g" /etc/fail2ban/fail2ban.conf
sed -i "s/#allowipv6 =.*/allowipv6 = auto/g" /etc/fail2ban/fail2ban.conf

# Check custom actions
echo "Checking for custom actions in /data/action.d..."
actions=$(ls -l /data/action.d | grep -E '^-' | awk '{print $9}')
for action in ${actions}; do
  if [ -f "/etc/fail2ban/action.d/${action}" ]; then
    echo "  WARNING: ${action} already exists and will be overriden"
    rm -f "/etc/fail2ban/action.d/${action}"
  fi
  echo "  Add custom action ${action}..."
  ln -sf "/data/action.d/${action}" "/etc/fail2ban/action.d/"
done

# Check custom filters
echo "Checking for custom filters in /data/filter.d..."
filters=$(ls -l /data/filter.d | grep -E '^-' | awk '{print $9}')
for filter in ${filters}; do
  if [ -f "/etc/fail2ban/filter.d/${filter}" ]; then
    echo "  WARNING: ${filter} already exists and will be overriden"
    rm -f "/etc/fail2ban/filter.d/${filter}"
  fi
  echo "  Add custom filter ${filter}..."
  ln -sf "/data/filter.d/${filter}" "/etc/fail2ban/filter.d/"
done

iptablesLegacy=0
if [ "$IPTABLES_MODE" = "auto" ] && ! iptables -L &> /dev/null; then
  echo "WARNING: iptables-nft is not supported by the host, falling back to iptables-legacy"
  iptablesLegacy=1
elif iptables -L 2>&1 | grep -q "Warning: iptables-legacy tables present"; then
  echo "WARNING: host has iptables-legacy tables present, falling back to iptables-legacy"
  iptablesLegacy=1
elif [ "$IPTABLES_MODE" = "legacy" ]; then
  echo "WARNING: iptables-legacy enforced"
  iptablesLegacy=1
fi
if [ "$iptablesLegacy" -eq 1 ]; then
  update-alternatives --set iptables /usr/sbin/iptables-legacy
  update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
fi

iptables -V
nft -v

# Listen for new log files
if [ -f "/etc/inotifywait.conf" ]; then
  echo "Listening for new log files..."
  inotifywait -m -r -e create --fromfile /etc/inotifywait.conf | while read path action file; do
    echo "The file '$file' appeared in directory '$path'"
    fail2ban-client reload
  done &
fi

exec "$@"
