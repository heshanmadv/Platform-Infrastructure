terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
  }
}

locals {
  values = {
    controller = {
      replicaCount = 1
      resources = {
        requests = { cpu = "50m", memory = "90Mi" }
        limits   = { cpu = "200m", memory = "180Mi" }
      }
      service = {
        # k3s ships its own ServiceLB (Klipper) controller, which gives
        # LoadBalancer Services a real external IP (the node's) with no
        # MetalLB or cloud LB needed — the right fit for a single-node Pi.
        type = "LoadBalancer"
      }
      ingressClassResource = {
        name    = var.ingress_class_name
        default = true
      }
    }
    # The default-backend pod (catch-all 404 responder) is extra weight
    # this cluster doesn't need to carry.
    defaultBackend = {
      enabled = false
    }
  }
}

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  values = [yamlencode(local.values)]
}
