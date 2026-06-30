#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================="
echo "    K3s DevOps Lab Bootstrap"
echo "=================================="

run() {
    echo
    echo "==> $1"
    bash "$SCRIPT_DIR/$2"
}

run "Loading configuration"      secret.sh
run "Configuring Traefik"        traefik.sh
run "Configuring Jenkins RBAC"   jenkins-rbac.sh

echo
echo "Bootstrap completed successfully."