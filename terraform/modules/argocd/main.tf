terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
  }
}

locals {
  values = {
    # No redis-ha, no per-component replica fan-out — single Pi, single
    # replica everywhere.
    redis-ha = {
      enabled = false
    }
    dex = {
      enabled = var.enable_dex
    }
    notifications = {
      enabled = var.enable_notifications
    }
    controller = {
      replicas = 1
      resources = {
        requests = { cpu = "50m", memory = "128Mi" }
        limits   = { cpu = "250m", memory = "256Mi" }
      }
    }
    server = merge(
      {
        replicas = 1
        resources = {
          requests = { cpu = "20m", memory = "64Mi" }
          limits   = { cpu = "100m", memory = "128Mi" }
        }
        service = {
          type = "ClusterIP"
        }
      },
      var.ingress_enabled ? {
        ingress = {
          enabled          = true
          ingressClassName = var.ingress_class_name
          hosts            = [var.ingress_host]
          annotations = {
            "cert-manager.io/cluster-issuer" = var.cluster_issuer_name
          }
          tls = [{
            secretName = "argocd-server-tls"
            hosts      = [var.ingress_host]
          }]
        }
      } : {}
    )
    repoServer = {
      replicas = 1
      resources = {
        requests = { cpu = "20m", memory = "64Mi" }
        limits   = { cpu = "100m", memory = "256Mi" }
      }
    }
    applicationSet = {
      replicaCount = 1
      resources = {
        requests = { cpu = "20m", memory = "64Mi" }
        limits   = { cpu = "100m", memory = "128Mi" }
      }
    }
    redis = {
      resources = {
        requests = { cpu = "20m", memory = "32Mi" }
        limits   = { cpu = "100m", memory = "64Mi" }
      }
    }
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  values = [yamlencode(local.values)]
}
