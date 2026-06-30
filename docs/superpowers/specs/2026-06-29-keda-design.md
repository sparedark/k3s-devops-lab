# KEDA event-driven autoscaling — design

**Date:** 2026-06-29
**Status:** Approved (brainstorm) → implementation
**Scope:** Add KEDA as a toggleable optional tool, plus a self-contained Cron demo. Cilium/Hubble explicitly out of scope (future session).

## Goal

Add KEDA (Kubernetes Event-Driven Autoscaler) to the lab as a `true/false`
toggle that mirrors the existing optional tools (`monitoring`, `loki`, …), and
ship a tiny self-contained demo so the user can *watch* event-driven autoscaling
(replicas climbing `0 → 3` and back) without any external dependencies.

## Why this fits the existing architecture

The repo has two install layers:

| Layer | Install path | Toggle | Live-flippable? |
|---|---|---|---|
| Foundation (`k3s` → `argocd` → `cloudflared`) | Ansible, ordered | hardcoded in `playbook.yml` | no (re-provision) |
| Optional tools | ArgoCD app-of-apps from Git | `enabled: true/false` in `gitops/root/values.yaml` | **yes** (`git push`) |

KEDA is an add-on installed *after* the cluster is healthy, so it belongs in the
**optional-tools layer** — no ansible / CNI changes needed. (This is exactly why
Cilium was dropped from scope: as the CNI it must live in the foundation layer
and cannot be a live ArgoCD toggle.)

## File changes

```
gitops/root/values.yaml            add  keda: { enabled: true }
gitops/root/templates/keda.yaml    NEW  emits 2 ArgoCD Applications
gitops/apps/keda-demo/deployment.yaml   NEW  nginx, replicas omitted
gitops/apps/keda-demo/scaledobject.yaml NEW  Cron trigger 0<->3
Vagrantfile                        add  mem += 512 if enabled?(vals,"keda")
```

## Components

### 1. `gitops/root/templates/keda.yaml`
Wrapped in `{{- if .Values.keda.enabled }}`. Emits two Applications:

- **`keda`** — Helm chart `keda` from `https://kedacore.github.io/charts`,
  `targetRevision: "2.20.1"` (pinned; bump manually, per repo convention).
  Namespace `keda`. `CreateNamespace=true`, `ServerSideApply=true`.
- **`keda-demo`** — directory source `path: gitops/apps/keda-demo` on this repo
  (`repoURL`/`branch` from values). Namespace `keda-demo`.
  `syncOptions: SkipDryRunOnMissingResource=true`.

### 2. `gitops/apps/keda-demo/deployment.yaml`
`nginx:1.27-alpine`, tiny resource requests. **`replicas` field intentionally
omitted** — KEDA's generated HPA owns that field; setting it fights the autoscaler.

### 3. `gitops/apps/keda-demo/scaledobject.yaml`
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
spec:
  scaleTargetRef: { name: keda-demo }
  minReplicaCount: 0
  maxReplicaCount: 3
  cooldownPeriod: 60
  triggers:
    - type: cron
      metadata:
        timezone: UTC
        start: "0,10,20,30,40,50 * * * *"   # scale up every 10 min
        end:   "5,15,25,35,45,55 * * * *"   # for 5 min, then back to 0
        desiredReplicas: "3"
```

### 4. `Vagrantfile`
Add `mem += 512 if enabled?(vals, "keda")` alongside the other sizing lines.
KEDA is lightweight (~200–300Mi total across 3 pods); 512MB is a safe budget.

## The key design decision: CRD-before-CR ordering

`ScaledObject` is a custom resource whose `kind` is only valid *after* KEDA's
chart installs the CRD. Applying the demo first errors with
`no matches for kind "ScaledObject"`. Resolved with
`SkipDryRunOnMissingResource=true` on the `keda-demo` Application: ArgoCD skips
schema pre-validation and retries until the CRD exists, then goes green. This is
the idiomatic ArgoCD approach to CRD/CR ordering (eventual consistency over
strict ordering).

## Testing / acceptance

- `kubectl get scaledobject,hpa,deploy -n keda-demo -w` — replicas go `0 → 3` on
  the window boundary, back to `0` after `cooldownPeriod`.
- `kubectl get pods -n keda` — operator, metrics-apiserver, admission webhook all Running.
- Flip `keda.enabled: false` + push → both Applications prune cleanly.

## Out of scope

- Cilium / Hubble / kube-proxy replacement (future session).
- Prometheus-based ScaledObject (would require `monitoring.enabled=true`).
- Exposing the demo via ingress (observed via kubectl; no public URL needed).

## Sources

- KEDA Helm chart 2.20.1 — https://github.com/kedacore/charts , https://artifacthub.io/packages/helm/kedacore/keda
