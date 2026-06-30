# k3s DevOps Lab

![License](https://img.shields.io/badge/License-Apache%202.0-blue?style=for-the-badge)

**Core stack** &nbsp;·&nbsp; *host → provisioning → cluster → GitOps → edge*

![VMware](https://img.shields.io/badge/VMware-607078?style=for-the-badge&logo=vmware&logoColor=white)
![Vagrant](https://img.shields.io/badge/Vagrant-1563FF?style=for-the-badge&logo=vagrant&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)
![k3s](https://img.shields.io/badge/k3s-FFC61C?style=for-the-badge&logo=k3s&logoColor=black)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)
![Argo CD](https://img.shields.io/badge/Argo%20CD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)
![Traefik](https://img.shields.io/badge/Traefik-24A1C1?style=for-the-badge&logo=traefikproxy&logoColor=white)
![Cloudflare](https://img.shields.io/badge/Cloudflare-F38020?style=for-the-badge&logo=cloudflare&logoColor=white)
![Cilium](https://img.shields.io/badge/Cilium-F8C517?style=for-the-badge&logo=cilium&logoColor=black)

**DevOps stack** &nbsp;·&nbsp; *observability + CI/CD + artifacts + autoscaling + serverless*

![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)
![Jenkins](https://img.shields.io/badge/Jenkins-D24939?style=for-the-badge&logo=jenkins&logoColor=white)
![Nexus](https://img.shields.io/badge/Nexus-1B1C30?style=for-the-badge&logo=sonatype&logoColor=white)
![KEDA](https://img.shields.io/badge/KEDA-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Knative](https://img.shields.io/badge/Knative-0865AD?style=for-the-badge&logo=knative&logoColor=white)

A fully-automated, modular DevOps learning lab on one VMware VM. Toggle tools on/off in
`values.yaml`; ArgoCD installs or prunes them. Every tool is reachable at
`https://<tool>.<your-domain>` via a Cloudflare Tunnel — no port-forwarding, no public IP.

> [!IMPORTANT]
> **This repo is a template — every tool ships `enabled: false`.** Out of the box you
> get a bare cluster (k3s + ArgoCD + Cloudflare Tunnel) and nothing else. To use it:
> **fork → set `domain` + `repoURL` in [`values.yaml`](gitops/root/values.yaml) → flip on
> the tools you want → `vagrant up`.** Enabling Jenkins + Nexus? Run the one-time
> [Bootstrap CI/CD](docs/bootstrap.md) step afterward.

> [!NOTE]
> Optional **eBPF networking**: set `cilium.enabled` to swap Flannel + kube-proxy
> for [Cilium + Hubble](docs/cilium.md). Unlike the ArgoCD tool toggles, it's a
> provision-time flag (needs a fresh `vagrant up`).

📖 **Docs:** [Prerequisites](docs/prerequisites.md) · [Quick start](docs/quickstart.md) · [Configuration](docs/configuration.md) · [Bootstrap CI/CD](docs/bootstrap.md) · [Tools](docs/tools.md) · [KEDA](docs/keda.md) · [Knative](docs/knative.md) · [Cilium + Hubble](docs/cilium.md) · [Passwords](docs/passwords.md) · [Networking](docs/networking.md) · [VM sizing](docs/vm-sizing.md) · [Troubleshooting](docs/troubleshooting.md)

🧩 **Want to deploy your own app?** Copy the [`example/`](example/) app — manifests + ArgoCD setup, fully explained.

```mermaid
flowchart LR
  v[gitops/root/values.yaml<br/>domain + tool flags] --> vg[vagrant up]
  vg --> an[Ansible bootstrap]
  an --> k3s[k3s]
  k3s -.->|cilium.enabled| ci[Cilium eBPF CNI<br/>+ Hubble]
  an --> cf[cloudflared tunnel]
  an --> ar[ArgoCD]
  ar -->|pulls public repo| gh[(GitHub)]
  gh --> tools[enabled tools<br/>grafana · loki · jenkins · nexus · keda]
```

## Get your passwords

Username is `admin` for every tool:

```powershell
vagrant ssh -c "bash /vagrant/scripts/passwords.sh"
```

## Bootstrap CI/CD

If you enabled **Jenkins + Nexus**, run the one-time setup once both are Healthy. It
creates the registry pull/push secrets, lets Traefik route to ExternalName services, and
grants Jenkins least-privilege RBAC to deploy into your namespace:

```powershell
vagrant ssh -c "bash /vagrant/scripts/config.sh"
```

Full walkthrough and the pipeline it unlocks: **[Bootstrap CI/CD](docs/bootstrap.md)**.

## License

[Apache License 2.0](LICENSE) © 2026 Xeze-org.