variable "name" {
  description = "Namespace name — also the tenant identifier."
  type        = string
}

variable "labels" {
  description = "Extra labels to apply to the namespace."
  type        = map(string)
  default     = {}
}

variable "resource_quota" {
  description = "Aggregate resource caps for the whole namespace (kubernetes ResourceQuota)."
  type = object({
    requests_cpu    = string
    requests_memory = string
    limits_cpu      = string
    limits_memory   = string
  })
}

variable "limit_range_default" {
  description = "Per-container default requests/limits applied when a pod spec doesn't set its own (kubernetes LimitRange)."
  type = object({
    cpu_request    = string
    cpu_limit      = string
    memory_request = string
    memory_limit   = string
  })
}

variable "deny_all_ingress" {
  description = "Install a default-deny-ingress NetworkPolicy for this namespace."
  type        = bool
  default     = true
}
