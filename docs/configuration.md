# Configuration

Two files drive everything. **Edit, `git push`, then `vagrant up`.**

## 1. `.env` — secrets only (gitignored, never committed)

### Follow This for env [Prerequisites](prerequisites.md) 

Copy `.env.example` → `.env` and fill in your Cloudflare values:

```ini
# Cloudflare API token — scopes:
#   Account:Cloudflare Tunnel:Edit  +  Zone:DNS:Edit  +  Zone:Zone:Read
CF_API_TOKEN=your-cloudflare-api-token
CF_ACCOUNT_ID=you-cloudflare-id

# Optional VM-size override. Blank = auto-compute from enabled tools.
VM_MEMORY=
VM_CPUS=
```

## 2. `gitops/root/values.yaml` — the public config ArgoCD reads

```yaml
# Your Cloudflare domain. Tools are exposed at <tool>.<domain>.
domain: your-domain.com

# YOUR fork — ArgoCD pulls manifests from here.
repoURL: https://github.com/<you>/<your-fork>.git
branch: main

# Tool toggles: true = ArgoCD installs it, false = ArgoCD prunes it.
monitoring:
  enabled: true      # Prometheus + Grafana
loki:
  enabled: true      # Loki logs (shown in Grafana)
jenkins:
  enabled: false     # heavy: +2GB
nexus:
  enabled: false     # heavy: +2GB
keda:
  enabled: true      # event-driven autoscaler + Cron demo — see docs/keda.md
kedaHttp:
  enabled: false     # KEDA HTTP Add-on (scale web apps to zero); needs keda.enabled
knative:
  enabled: false     # Knative Serving + Kourier (self-hosted Cloud Run) — heavy: +1GB

# Provision-time CNI flag (NOT an ArgoCD toggle — needs a fresh vagrant up).
cilium:
  enabled: true      # Cilium eBPF + Hubble replace Flannel + kube-proxy — see docs/cilium.md
```

> ⚠️ `repoURL` **must** point at your own fork, not the upstream repo — ArgoCD reads
> config from wherever this points.

> 💡 Enabling **Jenkins + Nexus**? After they sync, run the one-time
> [Bootstrap CI/CD](bootstrap.md) step (`scripts/config.sh`) to wire up registry
> secrets, Traefik routing, and Jenkins deploy RBAC.

## 3. Adding a new tool

> 👉 Prefer a working example? The [`example/`](../example/) folder has a complete,
> deployable app (raw manifests + an ArgoCD Application) you can copy.

Each tool is one ArgoCD `Application` template, guarded by its flag. Create
`gitops/root/templates/<tool>.yaml`:

```yaml
{{- if .Values.mytool.enabled }}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: mytool
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://charts.example.com      # the tool's Helm repo
    chart: mytool
    targetRevision: 1.2.3                     # pin the chart version
    helm:
      values: |
        ingress:
          enabled: true
          ingressClassName: traefik           # k3s uses Traefik, not nginx
          hosts:
            - mytool.{{ .Values.domain }}
  destination:
    server: https://kubernetes.default.svc
    namespace: mytool
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
{{- end }}
```

Then add its flag to `values.yaml`:

```yaml
mytool:
  enabled: true
```

`git push` — ArgoCD reconciles within ~3 min. Force it with
`vagrant ssh -c "bash /vagrant/scripts/sync.sh"`.

> Two patterns to copy from existing tools: `ingressClassName: traefik` (never `nginx`),
> and **no `tls:` block** — Cloudflare terminates TLS at the edge. See [Networking](networking.md).
