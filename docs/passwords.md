# Admin passwords

The username is `admin` for every tool. One command prints the password for each tool
that's actually deployed:

```powershell
vagrant ssh -c "bash /vagrant/scripts/passwords.sh"
```

```
== Admin credentials ==

  ArgoCD   user: admin
           pass: x7Kf9...
  Grafana  user: admin
           pass: kF9aZ2... (random per cluster)
```

Tools you haven't enabled are skipped. Both ArgoCD and Grafana get a strong random
password per cluster; change the rest after first login.

## Where each password lives

| Tool    | Source                                           |
| ------- | ------------------------------------------------ |
| ArgoCD  | secret `argocd-initial-admin-secret`             |
| Grafana | secret `grafana-admin` (random, created at provision) |
| Jenkins | secret `jenkins`                                 |
| Nexus   | file `/nexus-data/admin.password` inside the pod |

> A tool that's enabled but still syncing won't show yet — its secret doesn't exist until
> ArgoCD finishes (~3 min). Re-run the command shortly after.
