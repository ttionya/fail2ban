#!/bin/bash

TZ=${TZ:-UTC}

F2B_LOG_TARGET=${F2B_LOG_TARGET:-STDOUT}
F2B_LOG_LEVEL=${F2B_LOG_LEVEL:-INFO}
F2B_DB_PURGE_AGE=${F2B_DB_PURGE_AGE:-1d}
IPTABLES_MODE=${IPTABLES_MODE:-auto}

# Timezone
echo "Setting timezone to ${TZ}..."
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

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
elif [ "$IPTABLES_MODE" = "legacy" ]; then
  echo "WARNING: iptables-legacy enforced"
  iptablesLegacy=1
fi
if [ "$iptablesLegacy" -eq 1 ]; then
  update-alternatives --log /dev/null --set iptables /usr/sbin/iptables-legacy
  update-alternatives --log /dev/null --set ip6tables /usr/sbin/ip6tables-legacy
fi

iptables -V
nft -v

# Listening for new log files
if [ -f "/etc/inotifywait.conf" ]; then
  echo "Listening for new log files..."

  while IFS= read -r line; do
    [[ -z "${line}" || "${line}" =~ ^# ]] && continue
    if [[ "${line}" =~ (.*)\ \[(.*)\]$ ]]; then
      command="${BASH_REMATCH[1]}"
      jails="${BASH_REMATCH[2]}"
    else
      command="${line}"
      jails=""
    fi
    inotifywait ${command} | while read path action file; do
      echo "Detected '${action}' on '${file}' in '${path}'"
      if [[ -n "${jails}" ]]; then
        for jail in ${jails}; do
          echo "Reload jail ${jail}"
          fail2ban-client reload "${jail}"
        done
      else
        echo "Reload all jails"
        fail2ban-client reload
      fi
    done &
  done < "/etc/inotifywait.conf"
fi

exec "$@"
