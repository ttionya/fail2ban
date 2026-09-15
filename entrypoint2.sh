#!/usr/bin/env bash

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
