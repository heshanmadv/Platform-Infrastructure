terraform {
  required_version = ">= 1.5.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    # Used only by modules/cert-manager to create the bootstrap
    # ClusterIssuer/Certificate — see the comment in
    # ../../modules/cert-manager/cluster-issuer.tf for why kubectl_manifest
    # is used instead of the kubernetes provider's kubernetes_manifest.
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes = {
    config_path = var.kubeconfig_path
  }
}

provider "kubectl" {
  config_path      = var.kubeconfig_path
  load_config_file = true
}
