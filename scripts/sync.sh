#!/usr/bin/env bash
# Force ArgoCD to re-pull from Git and reconcile NOW. Runs inside the guest
# (invoked via: vagrant ssh -c "bash /vagrant/scripts/sync.sh").
set -uo pipefail
KUBECTL="sudo k3s kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml"
# A hard refresh re-reads Git; the automated sync policy then applies any diff.
$KUBECTL -n argocd annotate applications --all \
  argocd.argoproj.io/refresh=hard --overwrite || true
echo "Requested hard refresh of all ArgoCD applications."
