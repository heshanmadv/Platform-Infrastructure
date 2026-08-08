variable "namespace" {
  description = "Namespace to install cert-manager into."
  type        = string
  default     = "cert-manager"
}

variable "chart_version" {
  description = "cert-manager Helm chart version (jetstack/cert-manager on artifacthub.io). Pinned; bump deliberately."
  type        = string
  default     = "v1.21.0"
}
