# Prerequisites

One-time setup. Everything here is free for personal use.

## Software

1. **VMware Workstation Pro** — free for personal use, from
   [Broadcom](https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware+Workstation+Pro).
2. **Vagrant** — from [developer.hashicorp.com/vagrant/install](https://developer.hashicorp.com/vagrant/install).
3. **Vagrant VMware Utility** + provider plugin:
   ```powershell
   vagrant plugin install vagrant-vmware-desktop
   ```

## Cloudflare

4. **API token** — [dash.cloudflare.com/profile/api-tokens](https://dash.cloudflare.com/profile/api-tokens)
   → *Create Custom Token* with:
   - `Account` · `Cloudflare Tunnel` · `Edit`
   - `Zone` · `DNS` · `Edit`
   - `Zone` · `Zone` · `Read`

   Put it in `.env` as `CF_API_TOKEN`.

5. **Account ID** — click your domain in the dashboard; the middle URL segment is the ID:
   ```
   https://dash.cloudflare.com/6a62f1c74965310d79b3fb7f1ac4abde/domain.com
                              └──────────────┬───────────────┘
                                       this = Account ID
   ```
   Put it in `.env` as `CF_ACCOUNT_ID`.

## GitHub

6. **A public repo** (your fork). ArgoCD reads it with no token. Set its URL as `repoURL`
   in `gitops/root/values.yaml`.

→ Next: [Quick start](quickstart.md)
