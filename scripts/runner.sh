#!/usr/bin/env bash
set -euo pipefail

########################################
# Configuration
########################################

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

REPO_NAME="devops"
REPO_URL="https://code.xeze.org/api/packages/DevOps/helm"

RELEASE_NAME="gitea-runner"
CHART_NAME="gitea-runner"
CHART_VERSION="0.2.0"

NAMESPACE="gitea-runner"
SECRET_NAME="gitea-runner-registration"

GITEA_URL="https://code.xeze.org"

########################################
# Helm Repository
########################################

echo "==> Checking Helm repository..."

if ! helm repo list | awk '{print $1}' | grep -qx "${REPO_NAME}"; then
    echo "Adding Helm repository..."
    helm repo add "${REPO_NAME}" "${REPO_URL}"
fi

echo "Updating Helm repositories..."
helm repo update

########################################
# Registration Token
########################################

echo
read -rsp "Enter Gitea Runner Registration Token: " TOKEN
echo

########################################
# Namespace
########################################

echo "Creating namespace..."

kubectl create namespace "${NAMESPACE}" \
    --dry-run=client -o yaml | kubectl apply -f -

########################################
# Secret
########################################

echo "Creating registration secret..."

kubectl -n "${NAMESPACE}" delete secret "${SECRET_NAME}" \
    --ignore-not-found

kubectl -n "${NAMESPACE}" create secret generic "${SECRET_NAME}" \
    --from-literal=token="${TOKEN}"

unset TOKEN

########################################
# Install
########################################

echo "Installing Gitea Runner..."

helm upgrade --install "${RELEASE_NAME}" \
    "${REPO_NAME}/${CHART_NAME}" \
    --version "${CHART_VERSION}" \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    --set gitea.instanceURL="${GITEA_URL}"

########################################
# Finished
########################################

echo
echo "=============================================="
echo " Gitea Runner installed successfully!"
echo "=============================================="
echo
echo "Release   : ${RELEASE_NAME}"
echo "Namespace : ${NAMESPACE}"
echo "Chart     : ${CHART_NAME}"
echo "Version   : ${CHART_VERSION}"
echo "Gitea URL : ${GITEA_URL}"
echo
echo "Runner status:"
echo "kubectl get pods -n ${NAMESPACE}"