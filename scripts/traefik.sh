echo "--> Writing Traefik HelmChartConfig to disk..."
cat > traefik-allow-externalname.yaml <<'EOF'
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    providers:
      kubernetesIngress:
        allowExternalNameServices: true
EOF

echo "--> Applying Traefik configuration..."
kubectl apply -f traefik-allow-externalname.yaml

echo "--> Nexus authentication and Traefik config successfully applied!"