#!/bin/bash
# KBS — git credential helper: serves remote credentials from the repo's
# git-ignored .env, so no secret ever enters .git/config or the repo tree.
#
# Enable in a repo:
#   git config credential.helper '!bash scripts/git-credential-env.sh'
#
# git invokes this with "get" on push/pull; stdin carries protocol/host lines.
# Supported hosts and the .env keys they read:
#   github.com             -> GITHUB_TOKEN           (user: git)
#   $KBS_OFFSITE_HOST      -> KBS_OFFSITE_USERNAME / KBS_OFFSITE_PASSWORD
# Anything else is ignored (exit 0, no credentials emitted).
#
# .env must stay git-ignored — the credentials never enter the repo.
# Only serve credentials over https.

case "$1" in
  get)
    host=""
    proto=""
    while read -r line; do
      [ -z "$line" ] && break
      case "$line" in
        host=*) host="${line#host=}" ;;
        protocol=*) proto="${line#protocol=}" ;;
      esac
    done

    # Only serve credentials over https
    [ "$proto" = "https" ] || exit 0

    root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
    env_file="$root/.env"
    [ -f "$env_file" ] || exit 0

    read_env() {
      grep -E "^$1=" "$env_file" | head -1 | cut -d= -f2- | tr -d "\"'"
    }

    # GitHub
    if [ "$host" = "github.com" ]; then
      token="$(read_env GITHUB_TOKEN)"
      [ -n "$token" ] || exit 0
      echo "protocol=https"
      echo "host=github.com"
      echo "username=git"
      echo "password=$token"
      exit 0
    fi

    # Offsite host from .env (generic, no hardcoded names)
    offsite_host="$(read_env KBS_OFFSITE_HOST)"
    if [ -n "$offsite_host" ] && [ "$host" = "$offsite_host" ]; then
      user="$(read_env KBS_OFFSITE_USERNAME)"
      pass="$(read_env KBS_OFFSITE_PASSWORD)"
      [ -n "$user" ] && [ -n "$pass" ] || exit 0
      echo "protocol=https"
      echo "host=$host"
      echo "username=$user"
      echo "password=$pass"
      exit 0
    fi

    # Legacy: if KBS_OFFSITE_HOST not set but old vars exist, support them
    # for backward compatibility (can be removed after migration)
    if [ -z "$offsite_host" ]; then
      user="$(read_env KBS_OFFSITE_USERNAME)"
      pass="$(read_env KBS_OFFSITE_PASSWORD)"
      if [ -n "$user" ] && [ -n "$pass" ]; then
        echo "protocol=https"
        echo "host=$host"
        echo "username=$user"
        echo "password=$pass"
        exit 0
      fi
    fi

    exit 0
    ;;
esac
exit 0
