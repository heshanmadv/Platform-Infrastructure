# SingleBinary deployment: Loki runs as one pod with local filesystem
# storage on one PVC — the right shape for one Pi's worth of log volume.
# SimpleScalable/Distributed modes (the chart default) split Loki into
# separate read/write/backend components, which only makes sense once
# there's enough load to shard.
deploymentMode: SingleBinary

loki:
  # Single-tenant homelab cluster — no need for the multi-tenant
  # X-Scope-OrgID auth Loki normally requires.
  auth_enabled: false
  storage:
    type: filesystem
  limits_config:
    retention_period: ${retention_days * 24}h
    # Worst-case growth guardrails: Loki has no size-based retention like
    # Prometheus does, so a chatty pod could otherwise fill the PVC before
    # the next compaction pass prunes old data. These cap ingestion so that
    # can't happen unnoticed.
    ingestion_rate_mb: 4
    ingestion_burst_size_mb: 6
    per_stream_rate_limit: 3MB
    per_stream_rate_limit_burst: 5MB
    max_global_streams_per_user: 2000
  compactor:
    retention_enabled: true
    compaction_interval: 10m
    delete_request_store: filesystem

singleBinary:
  replicas: 1
  resources:
    requests:
      cpu: 50m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi
  persistence:
    enabled: true
    size: ${loki_storage_gi}Gi

gateway:
  resources:
    requests:
      cpu: 10m
      memory: 16Mi
    limits:
      cpu: 50m
      memory: 32Mi

# Skip everything not needed for a single-tenant, single-binary homelab
# install: the helm-test Job, self-scraping/self-monitoring dashboards
# (which would otherwise pull in their own ServiceMonitor + extra pod), and
# the always-on canary that continuously pings Loki to verify log delivery.
test:
  enabled: false
monitoring:
  serviceMonitor:
    enabled: false
  selfMonitoring:
    enabled: false
  lokiCanary:
    enabled: false
