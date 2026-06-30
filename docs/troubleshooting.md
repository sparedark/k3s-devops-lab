# Troubleshooting

### `chart not found` / `version matching constraint not found` on sync
Helm chart versions in `gitops/root/templates/*.yaml` are pinned exactly (no auto-update).
A pin can age out, or be wrong for that repo. Confirm the version actually exists, then bump
the app's `targetRevision`:
```bash
helm show chart <chart> --repo <repoURL> --version <x.y.z>   # errors if it doesn't exist
```
Note: the Sonatype `nexus-repository-manager` chart tops out around `64.x` — its numbering is
unrelated to the Nexus product version (see next entry).

### Nexus pod CrashLoopBackOff: `Unrecognized VM option 'UseCGroupMemoryLimitForHeap'`
The Sonatype chart's `appVersion` lags the product (stuck at `3.64.0`, below the `3.68.1`
that fixes CVE-2024-4956), so `nexus.yaml` pins a patched binary via `image.tag`. But the
chart's default JVM args carry `-XX:+UseCGroupMemoryLimitForHeap`, a **JDK 8–10-only flag
removed in JDK 11**. A modern Nexus image rejects it and the JVM aborts (exit 1). The fix is
already in `nexus.yaml`: `nexus.env` overrides `INSTALL4J_ADD_VM_PARAMS` to drop the flag and
set an explicit heap. When bumping `image.tag`, keep that override.

> Gotcha: `resources`, `env` and `securityContext` go **under `nexus:`** in this chart — a
> top-level `resources:` block is silently ignored.

### A tool didn't install after I enabled it
ArgoCD reconciles every ~3 min. Force it:
```powershell
vagrant ssh -c "bash /vagrant/scripts/sync.sh"
```
Then check health:
```powershell
bash scripts/status.sh
```

### Ingress returns 404 / no ADDRESS
k3s uses **Traefik**, not nginx. Ingresses must set `ingressClassName: traefik`. Confirm:
```bash
vagrant ssh -c "sudo k3s kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml get ingressclass"
```

### Heavy tool enabled but VM feels starved
Run `vagrant reload` so the VM resizes for the new flag set. See [VM sizing](vm-sizing.md).

### Passwords command shows nothing for a tool
It's either not enabled, or still syncing (secret not created yet). Re-run after ArgoCD
finishes. See [Passwords](passwords.md).

### Start over with Cloudflare
```bash
bash scripts/clean-cf.sh   # delete the tunnel + wildcard DNS
```
