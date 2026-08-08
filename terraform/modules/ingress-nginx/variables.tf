variable "namespace" {
  description = "Namespace to install ingress-nginx into."
  type        = string
  default     = "ingress-nginx"
}

variable "chart_version" {
  description = "ingress-nginx Helm chart version (kubernetes/ingress-nginx on artifacthub.io). Pinned; bump deliberately."
  type        = string
  default     = "4.15.1"
}

variable "ingress_class_name" {
  description = "IngressClass name this controller registers as (used by Ingress resources' ingressClassName)."
  type        = string
  default     = "nginx"
}
