#!/usr/bin/env bash

set -e

UPSTREAM_URL="https://github.com/crazy-max/docker-fail2ban.git"

CURRENT_BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")"
if [[ "${CURRENT_BRANCH}" == "upstream" ]]; then
  echo "Currently on upstream branch. Discarding all local changes and switching to master..."
  git reset --hard HEAD
  git checkout -f master
  echo "Switched to master branch."
fi

git fetch --no-tags "${UPSTREAM_URL}" master
git branch -f upstream FETCH_HEAD
git push origin upstream
