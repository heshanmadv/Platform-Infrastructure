variable "namespace" {
  description = "Namespace to install Consul into."
  type        = string
  default     = "consul"
}

variable "chart_version" {
  description = "consul Helm chart version (hashicorp/consul on artifacthub.io). Pinned; bump deliberately."
  type        = string
  default     = "2.0.2"
}

variable "datacenter" {
  description = "Consul datacenter name."
  type        = string
  default     = "dc1"
}

variable "server_storage_gi" {
  description = "Consul server PVC size (Raft data: KV store + service catalog), in GiB."
  type        = number
  default     = 1
}

variable "connect_enabled" {
  description = "Turn on Consul Connect (service mesh: sidecar injection + mTLS). Off by default — too heavy for this cluster size until multiple services actually need mTLS between them. Mesh/ingress/terminating gateways stay off even when this is enabled; they're a separate, later step."
  type        = bool
  default     = false
}
