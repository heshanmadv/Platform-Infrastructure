variable "namespace" {
  description = "Namespace for the whole observability stack (Prometheus, Grafana, Alertmanager, Loki, Alloy)."
  type        = string
  default     = "monitoring"
}

variable "cluster_name" {
  description = "Label attached to metrics/logs identifying this cluster."
  type        = string
  default     = "pi-cluster"
}

variable "retention_days" {
  description = "How long Prometheus and Loki keep data, in days."
  type        = number
  default     = 5
}

variable "prometheus_storage_gi" {
  description = "Prometheus PVC size, in GiB."
  type        = number
  default     = 2
}

variable "loki_storage_gi" {
  description = "Loki PVC size, in GiB."
  type        = number
  default     = 2
}

variable "kube_prometheus_stack_chart_version" {
  description = "kube-prometheus-stack Helm chart version (prometheus-community/kube-prometheus-stack on artifacthub.io). Pinned; bump deliberately."
  type        = string
  default     = "87.17.0"
}

variable "loki_chart_version" {
  description = "Loki Helm chart version (grafana/loki on artifacthub.io). Pinned; bump deliberately."
  type        = string
  default     = "7.1.0"
}

variable "alloy_chart_version" {
  description = "Grafana Alloy Helm chart version (grafana/alloy on artifacthub.io). Pinned; bump deliberately."
  type        = string
  default     = "1.10.1"
}
