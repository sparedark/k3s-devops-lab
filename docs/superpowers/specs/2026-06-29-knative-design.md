# Knative Serving (+ Kourier) — design

**Date:** 2026-06-29
**Status:** Approved (brainstorm) → implementation
**Scope:** Add Knative Serving as a toggleable tool — request-driven scale-to-zero
for HTTP services ("self-hosted Cloud Run"), using the lightweight **Kourier**
networking layer. Live ArgoCD toggle, default **off**.

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Install method | **Knative Operator (Helm) + `KnativeServing` CR** | Official GitOps-recommended path; separates install from config |
| Networking layer | **Kourier** | Just Envoy + a tiny control plane; Istio (the default) would drag a service mesh onto a single-node box |
| Layer | **ArgoCD optional-tools** (not foundation) | Knative installs after the cluster is healthy → normal live `true/false` toggle, no rebuild |
| Operator chart | `knative-operator/knative-operator` **`v1.22.2`** | Current stable (June 2026); note the `v` prefix |
| Serving version | **`1.22.1`** (pinned in the CR) | Matches the operator line |
| Access | **Port-forward Kourier** (documented) | Same safe/simple choice as Hubble; Traefik/cloudflared wiring is a documented future step |

## GitOps shape (mirrors the KEDA two-app pattern)

`gitops/root/templates/knative.yaml`, guarded `{{- if .Values.knative.enabled }}`,
emits two Applications:

1. **`knative-operator`** — Helm chart from `https://knative.github.io/operator`,
   `targetRevision: "v1.22.2"`, namespace `knative-operator`. Installs the
   operator + the `KnativeServing`/`KnativeEventing` CRDs.
2. **`knative-serving`** — directory source `gitops/apps/knative-serving/` (this
   repo), namespace `knative-serving`, `SkipDryRunOnMissingResource=true` so it
   settles before the operator's CRD exists (ArgoCD retries until green — same
   trick as `keda-demo`).

## The KnativeServing CR

`gitops/apps/knative-serving/knativeserving.yaml`:
```yaml
apiVersion: operator.knative.dev/v1beta1
kind: KnativeServing
metadata:
  name: knative-serving
  namespace: knative-serving
spec:
  version: "1.22.1"
  ingress:
    kourier:
      enabled: true
  config:
    network:
      ingress-class: "kourier.ingress.networking.knative.dev"
```

## File changes

```
gitops/root/values.yaml                          add  knative.enabled (default false)
gitops/root/templates/knative.yaml               NEW  2 ArgoCD Applications
gitops/apps/knative-serving/knativeserving.yaml  NEW  the KnativeServing CR
Vagrantfile                                       sizing +1024MB
docs/knative.md                                   NEW
docs/tools.md / configuration.md / vm-sizing.md / README.md   wire in the toggle
```

## CRD ordering

The `KnativeServing` CR's kind exists only after the operator installs its CRDs.
`SkipDryRunOnMissingResource=true` on the `knative-serving` app lets ArgoCD skip
schema pre-validation and retry until the operator (and CRD) are up. Identical to
the `keda-demo` resolution.

## Testing / acceptance

- `kubectl get knativeserving -n knative-serving` → `READY: True`.
- `kubectl get pods -n knative-serving` → controller, autoscaler, activator,
  webhook, net-kourier-controller, 3scale-kourier-gateway Running.
- Deploy a `Service` (serving.knative.dev) → it scales to 0 when idle, `0→1` on
  first request (buffered by the activator), back to 0 after the idle window.
- Access via `kubectl port-forward -n knative-serving svc/kourier 8080:80` + a
  `Host:` header for the route.

## RAM note

Knative + Kourier is ~8 pods, ~1 GB. On the 12 GB-clamped VM this competes with
Jenkins/Nexus/Harbor — enable deliberately; consider disabling a heavy tool while
experimenting.

## Out of scope

- Knative Eventing (only Serving).
- Traefik/cloudflared → Kourier ingress wiring + public URLs (future; port-forward now).
- Istio networking layer.

## Sources

- Knative install (Operator, GitOps) — https://knative.dev/docs/install/operator/knative-with-operators/
- Operator Helm chart — https://knative.github.io/operator
- net-kourier — https://github.com/knative-extensions/net-kourier
- Deploy Knative Services with ArgoCD — https://oneuptime.com/blog/post/2026-02-26-argocd-knative-services/view
