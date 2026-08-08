terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
  }
}

locals {
  values = {
    global = {
      name       = "consul"
      datacenter = var.datacenter
    }

    server = {
      replicas        = 1
      bootstrapExpect = 1
      storage         = "${var.server_storage_gi}Gi"
      resources = {
        requests = { cpu = "50m", memory = "128Mi" }
        limits   = { cpu = "200m", memory = "256Mi" }
      }
    }

    # No client agents: v2.x's dataplane architecture doesn't need
    # host-level Consul agents for KV/catalog-sync use, so this stays off
    # rather than running an extra DaemonSet pod on a single-node cluster.
    client = {
      enabled = false
    }

    ui = {
      enabled = true
      service = {
        type = "ClusterIP"
      }
    }

    # This is what actually delivers "service discovery" against a
    # Kubernetes cluster: it mirrors k8s Services into Consul's catalog.
    # toK8S stays off since nothing external registers into Consul (yet)
    # that k8s workloads would need to discover back.
    syncCatalog = {
      enabled  = true
      toConsul = true
      toK8S    = false
      resources = {
        requests = { cpu = "20m", memory = "32Mi" }
        limits   = { cpu = "50m", memory = "64Mi" }
      }
    }

    # Consul Connect (service mesh / sidecar injection + mTLS) stays off by
    # default — too heavy for this cluster size until multiple services
    # actually need mTLS between them. connect_enabled is the one switch to
    # flip later; mesh/ingress/terminating gateways are a separate,
    # still-off, later step even then.
    connectInject = {
      enabled = var.connect_enabled
    }
    meshGateway = {
      enabled = false
    }
    ingressGateways = {
      enabled = false
    }
    terminatingGateways = {
      enabled = false
    }
  }
}

resource "helm_release" "consul" {
  name             = "consul"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "consul"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  values = [yamlencode(local.values)]
}
