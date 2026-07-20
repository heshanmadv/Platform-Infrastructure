# Bootstrap: node setup and k3s install (Phase 0)

This document is the exact run order for taking a fresh Raspberry Pi to a
working single-node k3s cluster. It only covers Ansible — see the root
[README](../README.md) for how this fits with Terraform and the other repos.
All commands below are run from inside `ansible/`.

Cluster shape today: **one Raspberry Pi, running k3s in server mode, with
workload scheduling left enabled on that node** (k3s does not taint the
server node by default, so this needs no special flag). The inventory is
structured as `k3s_server` + `k3s_agents` groups so more Pis can be added as
agents later without restructuring anything — see the comments in
[`ansible/inventory/hosts.ini`](../ansible/inventory/hosts.ini).

## Prerequisites

1. Flash Raspberry Pi OS Lite (64-bit / ARM64) to the SD card. 64-bit is
   required — k3s and every platform service in this repo targets arm64.
2. On first boot, set a hostname, create a non-root user, and enable SSH.
3. Make sure you can SSH into the Pi with a key (not just a password):
   ```
   ssh-copy-id <user>@<pi-ip>
   ```
4. On your control machine (not the Pi), install Ansible and the collections
   this repo uses:
   ```
   cd ansible
   pip install ansible
   ansible-galaxy collection install -r requirements.yml
   ```

## Run order

All commands below assume your working directory is `ansible/` — that's
where `ansible.cfg` lives, and it's what makes the relative `inventory =`
path and group_vars auto-loading work.

1. **Edit the inventory.** Update `inventory/hosts.ini` with the Pi's real
   IP and SSH user under `[k3s_server]`.

2. **Check connectivity:**
   ```
   ansible -i inventory/hosts.ini k3s_cluster -m ping
   ```

3. **Run the playbook:**
   ```
   ansible-playbook -i inventory/hosts.ini playbooks/site.yml --ask-become-pass
   ```
   This runs, in order:
   - `roles/common` on every node in `k3s_cluster` — apt update/upgrade,
     base packages, timezone, unattended security upgrades, ufw rules
     (opens only the ports k3s needs: 22, 6443, 10250, 8472/udp), and SSH
     hardening (root login disabled; password auth disabled only if you set
     `common_disable_ssh_password_auth: true` — off by default so you can't
     lock yourself out).
   - `roles/k3s-server` on the `k3s_server` host — installs k3s via the
     official install script in server mode, waits for the node to report
     `Ready`, then fetches `/etc/rancher/k3s/k3s.yaml` back to this machine
     at `ansible/fetched/kubeconfig.yaml` (gitignored — never commit it) and
     rewrites its server URL from `127.0.0.1` to the Pi's real address.

4. **Verify** (from the repo root):
   ```
   export KUBECONFIG=$(pwd)/ansible/fetched/kubeconfig.yaml
   kubectl get nodes
   ```
   You should see one node, `Ready`, with no taints blocking scheduling.

## Notes

- This is deliberately **single-node**: one Pi is both the k3s server and
  the only place workloads run. When more Pis are added, they join as
  `k3s_agents` — the inventory and playbook are already shaped for that,
  but the `k3s-agent` role itself doesn't exist yet since there's nothing to
  target it at.
- Terraform (Phase 1 onward) consumes `ansible/fetched/kubeconfig.yaml`
  produced here. Ansible must run first.
- `ansible/inventory/group_vars/` (not a top-level `ansible/group_vars/`) is
  where group vars live, because Ansible auto-loads `group_vars/` relative
  to the inventory file's own directory (and separately, relative to the
  playbook's directory) — a `group_vars/` sitting as a sibling of both
  `inventory/` and `playbooks/` would silently never be picked up.
