terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
  }
}

locals {
  # Time-based retention (prometheus.prometheusSpec.retention /
  # loki.limits_config.retention_period) is the primary control for both
  # stores. Prometheus additionally gets a size-based backstop
  # (retentionSize), set below its PVC size, so it self-prunes instead of
  # filling the disk if actual series cardinality ever runs higher than
  # planned. Loki has no equivalent size-based retention knob, so its
  # worst-case growth is bounded instead via ingestion rate/stream limits
  # in values-loki.yaml.tpl.
  prometheus_retention_size_mb = floor(var.prometheus_storage_gi * 1024 * 0.75)
}

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.kube_prometheus_stack_chart_version
  namespace        = var.namespace
  create_namespace = true

  values = [
    templatefile("${path.module}/values-kube-prometheus-stack.yaml.tpl", {
      retention_days               = var.retention_days
      prometheus_storage_gi        = var.prometheus_storage_gi
      prometheus_retention_size_mb = local.prometheus_retention_size_mb
      cluster_name                 = var.cluster_name
    })
  ]
}

resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki"
  version          = var.loki_chart_version
  namespace        = var.namespace
  create_namespace = true

  values = [
    templatefile("${path.module}/values-loki.yaml.tpl", {
      retention_days  = var.retention_days
      loki_storage_gi = var.loki_storage_gi
    })
  ]
}

resource "helm_release" "alloy" {
  name             = "alloy"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "alloy"
  version          = var.alloy_chart_version
  namespace        = var.namespace
  create_namespace = true

  values = [
    templatefile("${path.module}/values-alloy.yaml.tpl", {
      namespace    = var.namespace
      cluster_name = var.cluster_name
    })
  ]

  # Not a hard runtime requirement (Alloy would just retry pushes if Loki
  # isn't up yet), but ordering it after Loki makes `terraform apply` output
  # easier to follow.
  depends_on = [helm_release.loki]
}
