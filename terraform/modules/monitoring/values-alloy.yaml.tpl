# Grafana Alloy is the Promtail successor (Promtail reached end-of-life in
# March 2026 — no further security fixes). Runs as a DaemonSet, tails pod
# logs via the Kubernetes API (loki.source.kubernetes — no hostPath mount
# of /var/log needed), and forwards them to Loki's gateway.
alloy:
  configMap:
    create: true
    content: |
      discovery.kubernetes "pod" {
        role = "pod"
        selectors {
          role  = "pod"
          field = "spec.nodeName=" + coalesce(sys.env("HOSTNAME"), constants.hostname)
        }
      }

      discovery.relabel "pod_logs" {
        targets = discovery.kubernetes.pod.targets

        rule {
          source_labels = ["__meta_kubernetes_namespace"]
          target_label  = "namespace"
        }

        rule {
          source_labels = ["__meta_kubernetes_pod_name"]
          target_label  = "pod"
        }

        rule {
          source_labels = ["__meta_kubernetes_pod_container_name"]
          target_label  = "container"
        }

        rule {
          source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_pod_container_name"]
          separator     = "/"
          target_label  = "job"
        }
      }

      loki.source.kubernetes "pod_logs" {
        targets    = discovery.relabel.pod_logs.output
        forward_to = [loki.process.pod_logs.receiver]
      }

      loki.process "pod_logs" {
        stage.static_labels {
          values = {
            cluster = "${cluster_name}",
          }
        }
        forward_to = [loki.write.default.receiver]
      }

      loki.write "default" {
        endpoint {
          url = "http://loki-gateway.${namespace}.svc.cluster.local/loki/api/v1/push"
        }
      }
  resources:
    requests:
      cpu: 20m
      memory: 64Mi
    limits:
      cpu: 100m
      memory: 128Mi

controller:
  type: daemonset
