# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Single-VM k3s DevOps lab.
#   - Config (domain, repo, tool flags) is read from gitops/root/values.yaml.
#   - Secrets (Cloudflare token) are read from .env.
#   - VM RAM/CPU auto-computed from the enabled flags (clamped 4-12GB / 4-8 CPU).
#   - Provisioned with ansible_local (Ansible runs INSIDE the guest -> Windows-friendly).

require "yaml"

# ── Minimal .env parser (KEY=VALUE) for the two secrets + sizing override ──────
def load_env(path)
  env = {}
  return env unless File.exist?(path)
  File.foreach(path) do |line|
    line = line.strip
    next if line.empty? || line.start_with?("#")
    key, _, val = line.partition("=")
    env[key.strip] = val.strip.gsub(/\A["']|["']\z/, "")
  end
  env
end

ENV_FILE  = File.join(__dir__, ".env")
VALS_FILE = File.join(__dir__, "gitops", "root", "values.yaml")

abort("\n[Vagrant] .env not found. Run:  cp .env.example .env  and add your Cloudflare token.\n\n") unless File.exist?(ENV_FILE)
abort("\n[Vagrant] gitops/root/values.yaml not found.\n\n") unless File.exist?(VALS_FILE)

env  = load_env(ENV_FILE)
vals = YAML.load_file(VALS_FILE) || {}

def enabled?(vals, key)
  vals.fetch(key, {}).is_a?(Hash) && vals[key]["enabled"] == true
end

domain = vals["domain"].to_s
repo   = vals["repoURL"].to_s
branch = (vals["branch"].to_s.empty? ? "main" : vals["branch"].to_s)
abort("\n[Vagrant] Set 'domain' and 'repoURL' in gitops/root/values.yaml.\n\n") if domain.empty? || repo.empty?

# ── Auto-sizing from the enabled flags ─────────────────────────────────────────
mem = 4096
cpu = 4
mem += 1024 if enabled?(vals, "monitoring")
mem += 512  if enabled?(vals, "loki")
if enabled?(vals, "jenkins") ; mem += 2048 ; cpu += 1 ; end
if enabled?(vals, "nexus")   ; mem += 2048 ; cpu += 1 ; end
if enabled?(vals, "harbor")  ; mem += 2048 ; cpu += 1 ; end
mem += 512  if enabled?(vals, "keda")
mem += 256  if enabled?(vals, "kedaHttp")  # interceptor + external scaler + operator
mem += 1024 if enabled?(vals, "knative")   # serving control plane + kourier (~8 pods)
mem += 768  if enabled?(vals, "cilium")   # cilium-agent + operator + hubble relay/ui

computed_mem = mem
mem = [[mem, 4096].max, 12288].min
cpu = [[cpu, 4].max, 8].min
mem = [[env["VM_MEMORY"].to_i, 4096].max, 12288].min unless env["VM_MEMORY"].to_s.empty?
cpu = [[env["VM_CPUS"].to_i,  4].max,    8].min     unless env["VM_CPUS"].to_s.empty?

warn "\n[Vagrant] WARNING: enabled tools want #{computed_mem}MB but clamped to 12288MB. "\
     "Consider disabling Jenkins, Nexus or Harbor.\n\n" if computed_mem > 12288
puts "[Vagrant] Sizing VM: #{mem}MB RAM, #{cpu} vCPU  (domain: #{domain})"

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "k3-kube"
  config.vm.network "private_network", ip: "192.168.56.50"

  config.vm.provider "vmware_desktop" do |v|
    v.memory = mem
    v.cpus   = cpu
    v.gui    = false
    v.vmx["virtualHW.version"] = "21"
    # 1 core per socket => any vCPU count is valid (VMware aborts when
    # numvcpus isn't a multiple of cores-per-socket, e.g. an odd count like 7).
    v.vmx["cpuid.coresPerSocket"] = "1"
  end

  config.vm.provision "ansible_local" do |a|
    a.playbook           = "ansible/playbook.yml"
    a.install_mode       = "default"   # apt (Ubuntu 24.04 is PEP 668; pip is blocked)
    a.compatibility_mode = "2.0"
    a.extra_vars = {
      domain:        domain,
      cf_api_token:  env["CF_API_TOKEN"],
      cf_account_id: env["CF_ACCOUNT_ID"],
      git_repo:      repo,
      git_branch:    branch,
      cilium_enabled: enabled?(vals, "cilium")
    }
  end
end
