#!/usr/bin/env bash
# Smoke test: curl each enabled tool's public URL and report HTTP status.
set -uo pipefail
cd "$(dirname "$0")/.."
. scripts/_lib.sh
domain="$(get_domain)"

declare -A hosts=( [monitoring]="grafana" [jenkins]="jenkins" [nexus]="nexus" )
rc=0
for f in monitoring jenkins nexus; do
  [ "$(flag_enabled "$f")" = "true" ] || continue
  url="https://${hosts[$f]}.${domain}"
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 "$url" || echo "000")
  if [[ "$code" =~ ^(200|301|302|401|403)$ ]]; then
    printf "  OK   %-40s [%s]\n" "$url" "$code"
  else
    printf "  FAIL %-40s [%s]\n" "$url" "$code"; rc=1
  fi
done
exit $rc
