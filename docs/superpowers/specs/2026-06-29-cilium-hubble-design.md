# Cilium (eBPF) + Hubble — design

**Date:** 2026-06-29
**Status:** Approved (brainstorm) → implementation
**Scope:** Replace K3s's default Flannel CNI + kube-proxy with Cilium (full
kube-proxy replacement) and install Hubble for observability. Foundation-layer
change, gated by a provision-time `cilium.enabled` flag.

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Datapath depth | **Full kube-proxy replacement** | Max learning value — Service routing moves entirely into eBPF; iptables `KUBE-*` chains vanish |
| Toggle mechanism | **`values.yaml` `cilium.enabled`** (provision-time) | Consistent "everything in values.yaml" UX. NOT live-flippable — flipping needs `vagrant destroy && up` |
| Hubble UI access | **Port-forward only** | Hubble UI has no auth and reveals full topology; exposing it publicly cuts against the repo's "no inbound holes" stance |
| Cilium version | **1.19.5** | Current stable (June 2026) |

## Why this is foundation-layer (not an ArgoCD app)

Cilium IS the CNI. After `--flannel-backend=none --disable-kube-proxy`, the node
is `NotReady` and no pod (including ArgoCD's own) can get an IP until Cilium
installs. ArgoCD therefore runs *too late* to install it. Cilium must be
installed imperatively by Ansible, **between the `k3s` and `argocd` roles**.

Cilium's agent runs with host networking, so it *can* start on a node with no
working pod network — that's what lets it bootstrap the very network everything
else needs.

## File changes

```
gitops/root/values.yaml                 add  cilium.enabled (provision-time flag)
Vagrantfile                             sizing +768MB + cilium_enabled extra_var
ansible/playbook.yml                    insert `cilium` role between k3s and argocd
ansible/roles/k3s/tasks/main.yml        conditional INSTALL_K3S_EXEC; conditional Ready-wait
ansible/roles/cilium/defaults/main.yml  NEW  cilium_version: "1.19.5"
ansible/roles/cilium/tasks/main.yml     NEW  helm install Cilium + Hubble, wait for Ready
docs/networking.md                      document the eBPF path + Hubble port-forward
```

## K3s install flags (when cilium.enabled)

```
--write-kubeconfig-mode 644 --flannel-backend=none --disable-network-policy --disable-kube-proxy
```
Traefik and servicelb are KEPT (cloudflared depends on Traefik). K3s default
CIDRs are kept (cluster 10.42.0.0/16, service 10.43.0.0/16).

## Cilium helm install (K3s-specific)

```
helm upgrade --install cilium cilium/cilium --version 1.19.5 --namespace kube-system \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=127.0.0.1 \      # REQUIRED w/o kube-proxy; 127.0.0.1 = single-node, dodges multi-NIC trap
  --set k8sServicePort=6443 \
  --set ipam.mode=kubernetes \          # use the PodCIDR K3s already allocates
  --set cni.exclusive=false \           # K3s-specific: don't wipe other CNI conf
  --set socketLB.enabled=true \         # socket-based LB for kube-proxy replacement
  --set operator.replicas=1 \           # single node
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true
```

## Ordering / role changes

- `k3s` role: build `INSTALL_K3S_EXEC` conditionally; **skip the "wait for Ready"
  task when cilium is enabled** (the node can't be Ready without a CNI — the
  `cilium` role does the wait after install).
- `cilium` role: entire role wrapped in `when: cilium_enabled | default(false)`.
  Install helm (idempotent, `creates:`), add repo (`--force-update`), helm
  upgrade --install with retries, wait for `ds/cilium` rollout, then wait for
  node Ready.
- `playbook.yml`: `roles: [k3s, cilium, argocd, cloudflared]`.

## Known limitation (documented, not coded around)

Because the `k3s` role only installs K3s `when: not k3s_bin.stat.exists`,
toggling `cilium.enabled` on an **already-provisioned** VM will NOT re-apply the
K3s flags — the `cilium` role would then try to install Cilium on a
Flannel+kube-proxy cluster and conflict. **Enabling/disabling Cilium requires a
fresh `vagrant destroy && vagrant up`.** This matches the existing provision-time
nature of the VM-sizing flags.

## Testing / acceptance

- `kubectl get nodes` → `Ready`.
- `kubectl -n kube-system get pods -l k8s-app=cilium` → Running; cilium-operator,
  hubble-relay, hubble-ui Running.
- `kubectl -n kube-system exec ds/cilium -- cilium status | grep KubeProxyReplacement`
  → `True`.
- `sudo iptables -t nat -L KUBE-SERVICES 2>&1` → chain gone / empty (the headline lesson).
- Hubble UI: `kubectl port-forward -n kube-system svc/hubble-ui 12000:80` → http://localhost:12000.
- ArgoCD, Traefik, cloudflared, KEDA all still functional on the new datapath.

## Out of scope

- Hubble UI ingress + Cloudflare Access (future; safe default is port-forward).
- Transparent encryption (WireGuard/IPsec), BGP, egress gateway.
- Multi-node (cluster is single-node).

## Sources

- Installing Cilium on K3s — https://oneuptime.com/blog/post/2026-03-14-install-cilium-on-k3s/view
- Cilium Helm install docs (stable 1.19.5) — https://docs.cilium.io/en/stable/installation/k8s-install-helm/
- Cilium releases — https://github.com/cilium/cilium/releases
