#!/usr/bin/env bash
# Shared helpers, sourced by the other scripts.  Not executed directly.

VALUES_FILE="${VALUES_FILE:-gitops/root/values.yaml}"

# Load .env into the environment (KEY=VALUE; ignores comments/blanks).
load_env() {
  local file="${1:-.env}"
  [ -f "$file" ] || { echo "ERROR: $file not found (cp .env.example .env)"; return 1; }
  set -a
  # shellcheck disable=SC1090
  . "$file"
  set +a
}

# Fail if any named variable is empty. Usage: require_env CF_API_TOKEN CF_ACCOUNT_ID
require_env() {
  load_env .env || return 1
  local missing=0 var
  for var in "$@"; do
    if [ -z "${!var}" ]; then echo "ERROR: $var is empty in .env"; missing=1; fi
  done
  return $missing
}

# Read the top-level `domain:` from values.yaml.
get_domain() {
  grep -E '^domain:' "$VALUES_FILE" | head -1 | sed -E 's/^domain:[[:space:]]*//' | tr -d '"'
}

# Echo "true"/"false" for a tool's enabled flag. Usage: flag_enabled monitoring
flag_enabled() {
  awk -v k="$1" '
    $0 ~ "^"k":"      { f=1; next }
    f && /enabled:/   { print ($0 ~ /true/) ? "true" : "false"; exit }
    f && /^[a-zA-Z]/  { f=0 }
  ' "$VALUES_FILE"
}
