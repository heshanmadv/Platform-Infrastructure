output "tenant_namespaces" {
  description = "Namespaces created for tenants."
  value       = { for k, m in module.tenant_namespaces : k => m.name }
}

output "argocd_access" {
  description = "How to reach the ArgoCD UI as currently configured."
  value = var.argocd_ingress_enabled ? (
    "https://${var.argocd_ingress_host}"
    ) : (
    "kubectl --kubeconfig ${var.kubeconfig_path} port-forward svc/argocd-server -n argocd 8080:443"
  )
}

output "grafana_access" {
  description = "How to reach the Grafana UI (ClusterIP-only, same reasoning as ArgoCD — no domain yet)."
  value       = "kubectl --kubeconfig ${var.kubeconfig_path} port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80"
}

output "consul_ui_access" {
  description = "How to reach the Consul UI (ClusterIP-only, same reasoning as ArgoCD/Grafana — no domain yet)."
  value       = "kubectl --kubeconfig ${var.kubeconfig_path} port-forward svc/consul-ui -n consul 8500:80"
}
