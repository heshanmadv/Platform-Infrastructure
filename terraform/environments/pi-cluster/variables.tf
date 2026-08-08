variable "kubeconfig_path" {
  description = "Path to the kubeconfig produced by Ansible (Phase 0)."
  type        = string
  default     = "../../../ansible/fetched/kubeconfig.yaml"
}

variable "argocd_ingress_enabled" {
  description = "Expose ArgoCD via ingress-nginx + cert-manager instead of ClusterIP-only. Leave false until you have a domain/hostname scheme — see modules/argocd."
  type        = bool
  default     = false
}

variable "argocd_ingress_host" {
  description = "Hostname for the ArgoCD Ingress. Only used when argocd_ingress_enabled = true."
  type        = string
  default     = ""
}

variable "monitoring_retention_days" {
  description = "How long Prometheus and Loki keep data, in days. Keep this conservative — it's a homelab Pi on an SD card, not cloud storage."
  type        = number
  default     = 5
}

variable "monitoring_prometheus_storage_gi" {
  description = "Prometheus PVC size, in GiB."
  type        = number
  default     = 2
}

variable "monitoring_loki_storage_gi" {
  description = "Loki PVC size, in GiB."
  type        = number
  default     = 2
}

variable "consul_server_storage_gi" {
  description = "Consul server PVC size (Raft data: KV store + service catalog), in GiB."
  type        = number
  default     = 1
}

variable "consul_connect_enabled" {
  description = "Turn on Consul Connect (service mesh: sidecar injection + mTLS). Off by default — flip on once multiple services actually need mTLS between them."
  type        = bool
  default     = false
}

variable "tenants" {
  description = "Map of tenant namespace name => config. Onboarding a new project/team is adding one entry here."
  type = map(object({
    labels = optional(map(string), {})
    resource_quota = object({
      requests_cpu    = string
      requests_memory = string
      limits_cpu      = string
      limits_memory   = string
    })
    limit_range_default = object({
      cpu_request    = string
      cpu_limit      = string
      memory_request = string
      memory_limit   = string
    })
    deny_all_ingress = optional(bool, true)
  }))
  default = {}
}
