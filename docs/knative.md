# Knative Serving — self-hosted Cloud Run

[Knative Serving](https://knative.dev/docs/serving/) gives you **request-driven
scale-to-zero** for HTTP services: deploy a container, get a URL, and it scales
to 0 when idle and `0 → 1` on the first request (the **activator** buffers that
request during cold start, so the caller just sees a slow first response). This
is the open-source engine Google Cloud Run is built on.

It complements KEDA rather than replacing it:
- **KEDA** → event-driven scaling (queues, cron, metrics) — background workers.
- **Knative** → request-driven scaling — front-door HTTP services.

| Flag      | Installs                                  | Networking | UI |
| --------- | ----------------------------------------- | ---------- | -- |
| `knative` | Knative Operator + Knative Serving        | Kourier    | —  |

## Enable / disable

```yaml
# gitops/root/values.yaml
knative:
  enabled: true     # false = ArgoCD prunes it
```
Live ArgoCD toggle (`git push`, ~3 min). **Heavy: +1 GB** (~8 pods) — on the
12 GB-clamped VM it competes with Jenkins/Nexus/Harbor, so enable deliberately
and run `vagrant reload` to resize.

## What gets installed

Two ArgoCD Applications (`gitops/root/templates/knative.yaml`):

1. **`knative-operator`** — the operator + CRDs, Helm chart pinned `v1.22.2`,
   into namespace `knative-operator`.
2. **`knative-serving`** — a `KnativeServing` CR
   (`gitops/apps/knative-serving/`) the operator reconciles, with **Kourier**
   as the ingress. Uses `SkipDryRunOnMissingResource=true` so it settles before
   the operator's CRD exists (ArgoCD retries until green).

**Networking layer = Kourier** — just an Envoy proxy + small control plane.
Istio is Knative's *default* but would pull a full service mesh onto a
single-node box, so we override to Kourier in the CR.

## Deploy a serverless service

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: hello
  namespace: default
spec:
  template:
    spec:
      containers:
        - image: ghcr.io/knative/helloworld-go:latest
          env:
            - name: TARGET
              value: "Knative on k3s"
```
`kubectl apply -f hello.yaml`. Knative creates the Deployment, Service, Route,
and autoscaler. With no traffic it scales to **0 pods**.

## Reach it (port-forward — no public DNS wired yet)

```bash
vagrant ssh
# forward Kourier, then call the route with its Host header:
sudo k3s kubectl port-forward -n knative-serving svc/kourier 8080:80 &
HOST=$(sudo k3s kubectl get ksvc hello -n default -o jsonpath='{.status.url}' | sed 's|http://||')
curl -H "Host: $HOST" http://localhost:8080
# watch it cold-start 0 -> 1, then idle back to 0:
sudo k3s kubectl get pods -n default -w
```

> Public URLs via the Cloudflare Tunnel (Traefik → Kourier) are a future step —
> see [Networking](networking.md). For now, access is port-forward only.

## Caveat

Cold start applies — great for lightweight, intermittently-used stateless HTTP
services; **not** for JVM-heavy apps like Jenkins/Nexus.

→ See also: [KEDA](keda.md) · [Tools & toggling](tools.md) · [VM sizing](vm-sizing.md)
