module "ingress_nginx" {
  source = "../../modules/ingress-nginx"
}

module "cert_manager" {
  source = "../../modules/cert-manager"
}

module "argocd" {
  source = "../../modules/argocd"

  ingress_enabled = var.argocd_ingress_enabled
  ingress_host    = var.argocd_ingress_host

  # Only load-bearing when ingress_enabled = true, but keeping the
  # dependency unconditional means flipping that variable on later doesn't
  # also require remembering to add this.
  depends_on = [module.cert_manager, module.ingress_nginx]
}

module "tenant_namespaces" {
  source   = "../../modules/namespace"
  for_each = var.tenants

  name                = each.key
  labels              = each.value.labels
  resource_quota      = each.value.resource_quota
  limit_range_default = each.value.limit_range_default
  deny_all_ingress    = each.value.deny_all_ingress
}

module "monitoring" {
  source = "../../modules/monitoring"

  retention_days        = var.monitoring_retention_days
  prometheus_storage_gi = var.monitoring_prometheus_storage_gi
  loki_storage_gi       = var.monitoring_loki_storage_gi
}

module "consul" {
  source = "../../modules/consul"

  server_storage_gi = var.consul_server_storage_gi
  connect_enabled   = var.consul_connect_enabled
}
