#!/bin/bash
# KBS — git credential helper: serves GITHUB_TOKEN from the repo's git-ignored .env
#
# Enable in a repo:
#   git config credential.helper '!bash scripts/git-credential-env.sh'
#
# git invokes this with "get" on push/pull; stdin carries protocol/host lines.
# Responds only for github.com, and only if the token exists in .env.
# .env must stay git-ignored — the token never enters the repo.

case "$1" in
  get)
    host=""
    while read -r line; do
      [ -z "$line" ] && break
      case "$line" in host=*) host="${line#host=}" ;; esac
    done
    [ "$host" = "github.com" ] || exit 0

    root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
    env_file="$root/.env"
    [ -f "$env_file" ] || exit 0

    token="$(grep -E '^GITHUB_TOKEN=' "$env_file" | head -1 | cut -d= -f2- | tr -d "\"'" )"
    [ -n "$token" ] || exit 0

    echo "protocol=https"
    echo "host=github.com"
    echo "username=git"
    echo "password=$token"
    ;;
esac
exit 0
