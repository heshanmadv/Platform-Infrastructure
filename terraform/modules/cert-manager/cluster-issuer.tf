# Bootstraps a self-signed CA, since there's no domain/ACME provider yet:
#
#   1. selfsigned-issuer — a bare SelfSigned ClusterIssuer, used only to
#      mint the CA certificate below.
#   2. bootstrap-ca       — a Certificate (isCA=true) signed by
#      selfsigned-issuer, stored as a Secret.
#   3. ca-issuer          — the ClusterIssuer that real workloads should
#      actually reference (via the cert-manager.io/cluster-issuer Ingress
#      annotation). It signs using the CA from step 2.
#
# When a real domain shows up, add a new ClusterIssuer for ACME/DNS-01
# alongside this one and repoint Ingress annotations at it — nothing here
# needs to change or be torn down; ca-issuer can stay for internal-only TLS.
#
# We use kubectl_manifest (not kubernetes_manifest) deliberately: the
# hashicorp/kubernetes provider validates custom resources against the
# cluster's CRD schema at plan time, which breaks on a first-ever apply
# because cert-manager's CRDs don't exist until the helm_release above has
# already run. kubectl_manifest applies the YAML directly without that
# plan-time schema lookup, so CRD install and CR creation can happen in one
# `terraform apply`.

locals {
  bootstrap_ca_secret_name = "bootstrap-ca-key-pair"
}

resource "kubectl_manifest" "selfsigned_issuer" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "selfsigned-issuer"
    }
    spec = {
      selfSigned = {}
    }
  })

  depends_on = [helm_release.cert_manager]
}

resource "kubectl_manifest" "bootstrap_ca_certificate" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "bootstrap-ca"
      namespace = var.namespace
    }
    spec = {
      isCA       = true
      commonName = "platform-infra-self-signed-ca"
      secretName = local.bootstrap_ca_secret_name
      privateKey = {
        algorithm = "ECDSA"
        size      = 256
      }
      issuerRef = {
        name  = "selfsigned-issuer"
        kind  = "ClusterIssuer"
        group = "cert-manager.io"
      }
    }
  })

  depends_on = [kubectl_manifest.selfsigned_issuer]
}

resource "kubectl_manifest" "ca_issuer" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "ca-issuer"
    }
    spec = {
      ca = {
        secretName = local.bootstrap_ca_secret_name
      }
    }
  })

  depends_on = [kubectl_manifest.bootstrap_ca_certificate]
}
