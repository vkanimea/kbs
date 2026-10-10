#!/usr/bin/env bash
# model-config.sh — single, model-agnostic source of provider/model wiring.
#
# KBS is model-agnostic by design: no script may hardcode a provider or model.
# Resolution order (first hit wins):
#   1. Environment (PI_PROVIDER / PI_MODEL)        — per-invocation override
#   2. Instance config file ($KBS/model.conf)      — per-install choice
#   3. FAIL LOUDLY                                 — never silently assume one
#
# The config file is `model.conf` in the data instance (git-ignored, machine-local),
# seeded from `model.conf.example` in the system repo. Format, one per line:
#   PI_PROVIDER=openrouter
#   PI_MODEL=deepseek/deepseek-v4-flash-0731
# Blank lines and lines beginning with # are ignored.
#
# Usage (source it, don't execute it):
#   . "$(dirname "$0")/model-config.sh"
#   kbs_resolve_model            # sets PI_PROVIDER / PI_MODEL, or exits 2
#
# Exit codes: 2 = not configured (message names the fix).

# Resolve the data instance dir: KBS env, else the repo containing this script's
# parent (scripts/..), else ~/kbs. A system repo is never used as the config home.
_kbs_instance_dir() {
  if [ -n "${KBS:-}" ] && [ -d "${KBS}" ]; then
    printf '%s\n' "${KBS}"
    return 0
  fi
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  # Prefer the data instance if the system repo is the caller but an instance exists.
  if [ -f "${HOME}/kbs/model.conf" ] || [ -d "${HOME}/kbs" ]; then
    printf '%s\n' "${HOME}/kbs"
  else
    printf '%s\n' "${here}"
  fi
}

# Read one key from model.conf (no subshell leakage; prints value or nothing).
_kbs_conf_get() {
  local key="$1" file="$2"
  [ -f "$file" ] || return 0
  # Strip comments/whitespace; return the last assignment for the key.
  awk -F= -v k="$key" '
    /^[[:space:]]*#/ { next }
    {
      name=$1; gsub(/^[[:space:]]+|[[:space:]]+$/,"",name)
      if (name==k) {
        val=substr($0, index($0,"=")+1)
        gsub(/^[[:space:]]+|[[:space:]]+$/,"",val)
        gsub(/^"|"$/,"",val); gsub(/^'\''|'\''$/,"",val)
        found=val
      }
    }
    END { if (found!="") print found }
  ' "$file"
}

# kbs_resolve_model [--quiet]
# Sets PI_PROVIDER and PI_MODEL. Exits 2 with a clear remediation message if
# neither env nor config supplies them. Pass --quiet to suppress the OK notice.
kbs_resolve_model() {
  local quiet=0
  [ "${1:-}" = "--quiet" ] && quiet=1

  local inst conf
  inst="$(_kbs_instance_dir)"
  conf="${KBS_MODEL_CONF:-$inst/model.conf}"

  if [ -z "${PI_PROVIDER:-}" ]; then
    PI_PROVIDER="$(_kbs_conf_get PI_PROVIDER "$conf")"
  fi
  if [ -z "${PI_MODEL:-}" ]; then
    PI_MODEL="$(_kbs_conf_get PI_MODEL "$conf")"
  fi

  if [ -z "${PI_PROVIDER:-}" ] || [ -z "${PI_MODEL:-}" ]; then
    local missing="PI_PROVIDER and PI_MODEL"
    [ -n "${PI_PROVIDER:-}" ] && missing="PI_MODEL"
    [ -n "${PI_MODEL:-}" ] && missing="PI_PROVIDER"
    {
      echo "ERROR: model not configured ($missing unset)." >&2
      echo "  KBS no longer hardcodes a provider/model (model-agnostic by design)." >&2
      echo "  Fix ONE of:" >&2
      echo "    a) create $conf with:" >&2
      echo "         PI_PROVIDER=openrouter" >&2
      echo "         PI_MODEL=<provider>/<model-id>" >&2
      echo "       (start from $(dirname "${BASH_SOURCE[0]}")/../templates/model.conf.example)" >&2
      echo "    b) export PI_PROVIDER=... PI_MODEL=... for a one-off run" >&2
    } >&2
    return 2
  fi

  [ "$quiet" -eq 1 ] || echo "(model: $PI_PROVIDER / $PI_MODEL — from ${conf##*/} or env)" >&2
  export PI_PROVIDER PI_MODEL
  return 0
}
