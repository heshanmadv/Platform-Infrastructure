terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubectl = {
      source = "alekc/kubectl"
    }
  }
}

# Pi-scale resource limits — cert-manager only needs to watch/reconcile a
# handful of Certificate objects on a cluster this size.
locals {
  values = {
    crds = {
      enabled = true
    }
    replicaCount = 1
    resources = {
      requests = { cpu = "10m", memory = "32Mi" }
      limits   = { cpu = "100m", memory = "128Mi" }
    }
    webhook = {
      replicaCount = 1
      resources = {
        requests = { cpu = "10m", memory = "32Mi" }
        limits   = { cpu = "50m", memory = "64Mi" }
      }
    }
    cainjector = {
      replicaCount = 1
      resources = {
        requests = { cpu = "10m", memory = "32Mi" }
        limits   = { cpu = "50m", memory = "64Mi" }
      }
    }
  }
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  values = [yamlencode(local.values)]
}
