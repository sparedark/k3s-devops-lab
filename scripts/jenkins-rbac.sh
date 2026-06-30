echo "--> Writing Jenkins RBAC (Least Privilege) to disk..."

# Prompt for the deployment namespace (default: practice)
read -p "Enter Deployment Namespace [default: practice]: " INPUT_NAMESPACE
TARGET_NAMESPACE="${INPUT_NAMESPACE:-practice}"

cat > jenkins-deployer-rbac.yaml <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: jenkins-deployer
  namespace: ${TARGET_NAMESPACE}
rules:
  # Workloads this chart manages
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

  # Core objects (required by Helm)
  - apiGroups: [""]
    resources: ["services", "secrets", "configmaps", "pods", "events"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

  # Ingress
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

  # KEDA HTTP Add-on
  - apiGroups: ["http.keda.sh"]
    resources: ["httpscaledobjects"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins-deployer-binding
  namespace: ${TARGET_NAMESPACE}
subjects:
  - kind: ServiceAccount
    name: default
    namespace: jenkins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: jenkins-deployer
EOF

echo "--> Applying Jenkins RBAC configuration..."
kubectl apply -f jenkins-deployer-rbac.yaml

echo "--> Cluster environment successfully secured and configured!"