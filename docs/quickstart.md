# Quick start

> **Fork this repo first** and clone your fork — ArgoCD pulls from *your* repository, so
> the config push below must land there, not on the upstream repo.

```powershell
# 1. Secrets (gitignored): the Cloudflare token
Copy-Item .env.example .env        # fill in CF_API_TOKEN + CF_ACCOUNT_ID

# 2. Config: set your domain + which tools you want, then commit + push to your fork
git add gitops/root/values.yaml; git commit -m "configure lab"; git push

# 3. Boot everything
vagrant up
```

`vagrant up` reads `values.yaml` (domain, flags, VM sizing) and `.env` (Cloudflare token),
then Ansible bootstraps k3s + ArgoCD + the tunnel. ArgoCD installs the tools you enabled.

## Everyday commands

```powershell
vagrant up          # boot + bootstrap (or apply provisioning changes)
vagrant ssh         # shell into the VM
vagrant reload      # re-read VM size after toggling heavy tools
vagrant destroy -f  # tear down
```

→ Next: [Tools](tools.md) · [Passwords](passwords.md)
