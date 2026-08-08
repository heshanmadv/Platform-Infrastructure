terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

resource "kubernetes_namespace" "this" {
  metadata {
    name   = var.name
    labels = var.labels
  }
}

resource "kubernetes_resource_quota" "this" {
  metadata {
    name      = "${var.name}-quota"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"    = var.resource_quota.requests_cpu
      "requests.memory" = var.resource_quota.requests_memory
      "limits.cpu"      = var.resource_quota.limits_cpu
      "limits.memory"   = var.resource_quota.limits_memory
    }
  }
}

resource "kubernetes_limit_range" "this" {
  metadata {
    name      = "${var.name}-limits"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  spec {
    limit {
      type = "Container"

      default = {
        cpu    = var.limit_range_default.cpu_limit
        memory = var.limit_range_default.memory_limit
      }

      default_request = {
        cpu    = var.limit_range_default.cpu_request
        memory = var.limit_range_default.memory_request
      }
    }
  }
}

resource "kubernetes_network_policy" "default_deny_ingress" {
  count = var.deny_all_ingress ? 1 : 0

  metadata {
    name      = "default-deny-ingress"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }
}
