variable "namespace" {
  description = "Namespace to install ArgoCD into."
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "argo-cd Helm chart version (argo/argo-cd on artifacthub.io). Pinned; bump deliberately."
  type        = string
  default     = "10.1.4"
}

variable "enable_dex" {
  description = "Dex (SSO) is disabled by default to save resources on a single Pi. Enable once you actually need SSO."
  type        = bool
  default     = false
}

variable "enable_notifications" {
  description = "ArgoCD's notifications controller, disabled by default to save resources."
  type        = bool
  default     = false
}

variable "ingress_enabled" {
  description = "Expose ArgoCD via Ingress (ingress-nginx + cert-manager) instead of ClusterIP-only. Off by default — with no domain yet, access via `kubectl port-forward svc/argocd-server -n argocd 8080:443`. Flip this on once you have a hostname scheme."
  type        = bool
  default     = false
}

variable "ingress_class_name" {
  description = "IngressClass to use. Only relevant when ingress_enabled = true; must match the ingress-nginx module's ingress_class_name."
  type        = string
  default     = "nginx"
}

variable "ingress_host" {
  description = "Hostname for the ArgoCD Ingress. Required when ingress_enabled = true."
  type        = string
  default     = ""
}

variable "cluster_issuer_name" {
  description = "cert-manager ClusterIssuer to request the Ingress TLS cert from. Only relevant when ingress_enabled = true."
  type        = string
  default     = "ca-issuer"
}
