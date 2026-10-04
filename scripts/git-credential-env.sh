#!/bin/bash
# KBS — git credential helper: serves remote credentials from the repo's
# git-ignored .env, so no secret ever enters .git/config or the repo tree.
#
# Enable in a repo:
#   git config credential.helper '!bash scripts/git-credential-env.sh'
#
# git invokes this with "get" on push/pull; stdin carries protocol/host lines.
# Supported hosts and the .env keys they read:
#   github.com            -> GITHUB_TOKEN      (user: git)
#   git.dustybranch.com   -> GITEA_USERNAME / GITEA_PASSWORD   (offsite Gitea
#                            on harbor01, reached via Cloudflare Tunnel)
# Anything else is ignored (exit 0, no credentials emitted).
#
# .env must stay git-ignored — the credentials never enter the repo.

case "$1" in
  get)
    host=""
    while read -r line; do
      [ -z "$line" ] && break
      case "$line" in host=*) host="${line#host=}" ;; esac
    done

    root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
    env_file="$root/.env"
    [ -f "$env_file" ] || exit 0

    read_env() {
      grep -E "^$1=" "$env_file" | head -1 | cut -d= -f2- | tr -d "\"'"
    }

    case "$host" in
      github.com)
        token="$(read_env GITHUB_TOKEN)"
        [ -n "$token" ] || exit 0
        echo "protocol=https"
        echo "host=github.com"
        echo "username=git"
        echo "password=$token"
        ;;
      git.dustybranch.com)
        user="$(read_env GITEA_USERNAME)"
        pass="$(read_env GITEA_PASSWORD)"
        [ -n "$user" ] && [ -n "$pass" ] || exit 0
        echo "protocol=https"
        echo "host=git.dustybranch.com"
        echo "username=$user"
        echo "password=$pass"
        ;;
      *)
        exit 0
        ;;
    esac
    ;;
esac
exit 0
