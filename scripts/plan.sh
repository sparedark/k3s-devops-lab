#!/usr/bin/env bash
# Ansible dry-run of the bootstrap. Runs inside the guest
# (invoked via: vagrant ssh -c "bash /vagrant/scripts/plan.sh").
set -euo pipefail
cd /vagrant
sudo ansible-playbook ansible/playbook.yml --check
