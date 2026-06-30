#!/usr/bin/env bash
# Show enabled flags + ArgoCD app health + tool URLs.
set -uo pipefail
cd "$(dirname "$0")/.."
. scripts/_lib.sh
domain="$(get_domain)"

echo "== Flags (values.yaml) =="
for f in monitoring loki jenkins nexus; do printf "  %-12s %s\n" "$f" "$(flag_enabled "$f")"; done

echo
echo "== ArgoCD applications =="
vagrant ssh -c "sudo k3s kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml -n argocd \
  get applications.argoproj.io \
  -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status" \
  2>/dev/null || echo "  (VM not reachable — is it up?)"

echo
echo "== URLs =="
echo "  https://argocd.${domain}   (always on)"
# Loki has no UI — view its logs inside Grafana, so it's not listed here.
declare -A hosts=( [monitoring]="grafana" [jenkins]="jenkins" [nexus]="nexus" )
for f in monitoring jenkins nexus; do
  [ "$(flag_enabled "$f")" = "true" ] && echo "  https://${hosts[$f]}.${domain}"
done
