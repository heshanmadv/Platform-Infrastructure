# platform-infra

Infrastructure-as-code for a Kubernetes platform running on a Raspberry Pi
cluster (k3s, ARM64). This repo owns **cluster-level infrastructure only**:
bootstrapping the node(s) and installing the platform services that ArgoCD
and applications depend on.

## Scope boundary

This repo is one of three:

| Repo | Responsibility |
|---|---|
| **platform-infra** (this repo) | Node bootstrap (Ansible) + cluster platform services (Terraform): ArgoCD, cert-manager, observability, Consul, namespaces/tenancy. |
| `common-service-chart` | Generic Helm chart used to deploy any application to the cluster, any language/runtime. |
| `platform-gitops` | ArgoCD's source of truth — renders `common-service-chart` per app and syncs it to the cluster. |

**This repo must never contain application Deployment/Service manifests.**
Those belong in `platform-gitops` (via `common-service-chart`). Mixing them
in here causes Terraform and ArgoCD to fight over ownership of the same
resources. If you're adding a Deployment, Service, or Ingress for an actual
app, it does not belong in this repo.

## Order of operations

1. **Ansible** (`ansible/`) — bootstraps the Raspberry Pi node(s) and
   installs k3s. Produces a kubeconfig at `ansible/fetched/kubeconfig.yaml`
   (gitignored). See [docs/bootstrap.md](docs/bootstrap.md) for the exact
   run order.
2. **Terraform** (`terraform/environments/pi-cluster`) — points at the
   kubeconfig from step 1 and installs cluster platform services via the
   `kubernetes`, `helm`, and `kubectl` providers:
   - `ingress-nginx` — ingress controller, exposed through k3s's built-in
     ServiceLB (no MetalLB needed on a single node).
   - `cert-manager` — plus a self-signed ClusterIssuer chain
     (`selfsigned-issuer` → bootstrap CA cert → `ca-issuer`) since there's
     no domain yet. Swapping in a real ACME/DNS-01 issuer later is additive
     — see `terraform/modules/cert-manager/cluster-issuer.tf`.
   - `argocd` — ClusterIP-only for now (`kubectl port-forward svc/argocd-server
     -n argocd 8080:443` to reach the UI); one variable flips it to an
     Ingress once there's a hostname scheme.
   - `namespace` (reusable module) — one tenant namespace per entry in the
     `tenants` variable, each with a ResourceQuota, LimitRange, and
     default-deny NetworkPolicy. The FYP project is the first tenant.
   - `monitoring` — kube-prometheus-stack (Prometheus, Grafana, Alertmanager)
     and Loki + Grafana Alloy (the maintained Promtail successor — Promtail
     itself hit end-of-life in March 2026), sized for an SD-card-backed Pi:
     5-day retention and a 2Gi PVC each for Prometheus and Loki by default
     (`monitoring_retention_days`, `monitoring_prometheus_storage_gi`,
     `monitoring_loki_storage_gi`). Prometheus also enforces a size-based
     retention backstop below its PVC size, and Loki has ingestion rate
     limits, so both self-protect if actual usage runs higher than planned
     instead of quietly filling the SD card.
   - `consul` — service discovery + KV only. `syncCatalog` mirrors k8s
     Services into Consul's catalog (that's what makes "service discovery"
     actually mean something against a k8s cluster); no client-agent
     DaemonSet (not needed for KV/catalog-sync on the v2.x dataplane
     architecture); Consul Connect (service mesh/sidecar injection + mTLS)
     stays off by default — `consul_connect_enabled` flips it on once
     multiple services actually need mTLS between them.

   ```
   cd terraform/environments/pi-cluster
   cp terraform.tfvars.example terraform.tfvars   # then edit it
   terraform init
   terraform plan
   terraform apply
   ```

Ansible must run first; Terraform depends on its output (`ansible/fetched/kubeconfig.yaml`).

## Cluster shape

Single-node by design, for now: one Raspberry Pi running k3s in server
mode, with workload scheduling left enabled on that same node (no taint —
there are no agents to schedule onto yet). The inventory and playbook are
structured so adding more Pis as agents later is additive, not a rewrite —
see [docs/bootstrap.md](docs/bootstrap.md).

## Hardware constraints

Everything in this repo targets ARM64 (Raspberry Pi) and is sized for a
homelab-scale cluster, not cloud defaults — reduced resource
requests/limits and replica counts throughout. Any Helm chart or image used
here is verified to publish arm64 images before being adopted.
