#!/bin/bash

# Interactively prompt for variables with smart defaults
read -p "Enter Target Namespace [default: practice]: " INPUT_NAMESPACE
TARGET_NAMESPACE="${INPUT_NAMESPACE:-practice}"

read -p "Enter Nexus Domain (e.g., nexus.example.com) [default: nexus.xeze.org]: " INPUT_DOMAIN
NEXUS_DOMAIN="${INPUT_DOMAIN:-nexus.xeze.org}"

#  Securely prompt for the password so it doesn't get saved in bash history
read -s -p "Enter Nexus Admin Password: " NEXUS_PASSWORD
echo ""

# Set KUBECONFIG for this session and append to bashrc if missing
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
if ! grep -q "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" ~/.bashrc; then
  echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> ~/.bashrc
fi

echo "--> Adding Nexus Helm repository..."
helm repo add custom-nexus https://${NEXUS_DOMAIN}/repository/helm/ \
  --username admin \
  --password "$NEXUS_PASSWORD"

echo "--> Ensuring namespace '$TARGET_NAMESPACE' exists..."
kubectl get namespace "$TARGET_NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$TARGET_NAMESPACE"

echo "--> Creating docker-registry secret 'nexus-pull' in namespace '$TARGET_NAMESPACE'..."
# Using dry-run and apply makes this command idempotent
kubectl create secret docker-registry nexus-pull \
  --docker-server="${NEXUS_DOMAIN}" \
  --docker-username=admin \
  --docker-password="$NEXUS_PASSWORD" \
  -n "$TARGET_NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -


echo "--> Creating docker-registry secret 'nexus-docker-config' in namespace 'jenkins'..."
kubectl create secret docker-registry nexus-docker-config \
  --docker-server="${NEXUS_DOMAIN}" \
  --docker-username=admin \
  --docker-password="$NEXUS_PASSWORD" \
  -n jenkins \
  --dry-run=client -o yaml | kubectl apply -f -