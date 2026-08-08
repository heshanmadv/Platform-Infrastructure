# Homelab-scale kube-prometheus-stack for a single Raspberry Pi node.
#
# k3s doesn't expose separate controller-manager/scheduler/etcd/kube-proxy
# metrics endpoints the way kubeadm clusters do (they're embedded in the
# k3s binary, not run as separately-scraped components) — left enabled,
# these default ServiceMonitors just report permanently-down targets, so
# they're disabled here.
kubeControllerManager:
  enabled: false
kubeScheduler:
  enabled: false
kubeEtcd:
  enabled: false
kubeProxy:
  enabled: false

prometheus:
  prometheusSpec:
    replicas: 1
    externalLabels:
      cluster: ${cluster_name}
    retention: ${retention_days}d
    # Safety backstop: prune early rather than fill the PVC if actual
    # series cardinality runs higher than expected. See main.tf.
    retentionSize: ${prometheus_retention_size_mb}MB
    resources:
      requests:
        cpu: 50m
        memory: 256Mi
      limits:
        cpu: 300m
        memory: 512Mi
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: ${prometheus_storage_gi}Gi

alertmanager:
  alertmanagerSpec:
    replicas: 1
    resources:
      requests:
        cpu: 10m
        memory: 16Mi
      limits:
        cpu: 50m
        memory: 32Mi
    # No storageSpec: alert/silence state is ephemeral. Losing it on a pod
    # restart is an acceptable homelab tradeoff against the PVC it'd cost.

grafana:
  replicas: 1
  persistence:
    enabled: false
  resources:
    requests:
      cpu: 20m
      memory: 64Mi
    limits:
      cpu: 100m
      memory: 128Mi

prometheusOperator:
  resources:
    requests:
      cpu: 10m
      memory: 32Mi
    limits:
      cpu: 100m
      memory: 128Mi

kube-state-metrics:
  resources:
    requests:
      cpu: 10m
      memory: 32Mi
    limits:
      cpu: 50m
      memory: 64Mi

prometheus-node-exporter:
  resources:
    requests:
      cpu: 10m
      memory: 16Mi
    limits:
      cpu: 50m
      memory: 32Mi
