#!/usr/bin/env bash
# Delete the Cloudflare tunnel + wildcard DNS record created for this lab,
# so re-running `make up` doesn't accumulate orphaned resources.
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/_lib.sh
require_env CF_API_TOKEN CF_ACCOUNT_ID
DOMAIN="$(get_domain)"

API="https://api.cloudflare.com/client/v4"
AUTH=(-H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json")
TUNNEL_NAME="k3-kube"

# Look up zone id from the domain.
ZONE_ID=$(curl -s "${AUTH[@]}" "${API}/zones?name=${DOMAIN}" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

# Delete the wildcard DNS record (*.DOMAIN) if present.
if [ -n "$ZONE_ID" ]; then
  REC_ID=$(curl -s "${AUTH[@]}" "${API}/zones/${ZONE_ID}/dns_records?name=*.${DOMAIN}" \
    | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  if [ -n "$REC_ID" ]; then
    curl -s -X DELETE "${AUTH[@]}" "${API}/zones/${ZONE_ID}/dns_records/${REC_ID}" >/dev/null
    echo "Deleted wildcard DNS *.${DOMAIN}"
  fi
fi

# Delete the tunnel (must delete its connections first; cleanup=true does that).
TUN_ID=$(curl -s "${AUTH[@]}" \
  "${API}/accounts/${CF_ACCOUNT_ID}/cfd_tunnel?name=${TUNNEL_NAME}&is_deleted=false" \
  | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -n "$TUN_ID" ]; then
  curl -s -X DELETE "${AUTH[@]}" \
    "${API}/accounts/${CF_ACCOUNT_ID}/cfd_tunnel/${TUN_ID}?cleanup=true" >/dev/null
  echo "Deleted tunnel ${TUNNEL_NAME} (${TUN_ID})"
else
  echo "No tunnel named ${TUNNEL_NAME} found."
fi
