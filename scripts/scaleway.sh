#!/bin/bash

# Interactively prompt for variables
read -p "Enter Target Namespace for Deployment [default: practice]: " INPUT_NAMESPACE
TARGET_NAMESPACE="${INPUT_NAMESPACE:-practice}"

read -p "Enter Scaleway Registry Domain [default: rg.pl-waw.scw.cloud]: " INPUT_DOMAIN
SCW_REGISTRY_DOMAIN="${INPUT_DOMAIN:-rg.pl-waw.scw.cloud}"

# Securely prompt for the Scaleway Secret Key
read -s -p "Enter Scaleway Secret Key: " SCW_SECRET_KEY
echo ""


echo "--> Ensuring namespace '$TARGET_NAMESPACE' exists..."
kubectl get namespace "$TARGET_NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$TARGET_NAMESPACE"

echo "--> Creating 'scaleway-pull' secret in '$TARGET_NAMESPACE' namespace..."
kubectl create secret docker-registry scaleway-pull \
  --docker-server="${SCW_REGISTRY_DOMAIN}" \
  --docker-username=nologin \
  --docker-password="$SCW_SECRET_KEY" \
  -n "$TARGET_NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "--> Ensuring namespace 'jenkins' exists..."
kubectl get namespace jenkins >/dev/null 2>&1 || kubectl create namespace jenkins

echo "--> Creating 'scaleway-docker-config' secret in 'jenkins' namespace..."
kubectl create secret docker-registry scaleway-docker-config \
  --docker-server="${SCW_REGISTRY_DOMAIN}" \
  --docker-username=nologin \
  --docker-password="$SCW_SECRET_KEY" \
  -n jenkins \
  --dry-run=client -o yaml | kubectl apply -f -

echo "--> Ensuring namespace 'gitea-runner' exists..."
kubectl get namespace gitea-runner >/dev/null 2>&1 || kubectl create namespace gitea-runner

echo "--> Creating 'scaleway-push' secret in 'gitea-runner' namespace..."
kubectl create secret docker-registry scaleway-push \
  --docker-server="${SCW_REGISTRY_DOMAIN}" \
  --docker-username=nologin \
  --docker-password="$SCW_SECRET_KEY" \
  -n gitea-runner \
  --dry-run=client -o yaml | kubectl apply -f -

echo "--> Setup Complete! 🚀"