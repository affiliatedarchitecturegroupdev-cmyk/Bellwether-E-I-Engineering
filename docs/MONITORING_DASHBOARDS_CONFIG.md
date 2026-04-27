# Monitoring Dashboards Configuration

This document describes the monitoring dashboards and configuration for BEIE Nexus observability.

## Grafana Dashboard Setup

### Installation

```bash
# Add Grafana Helm repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Grafana
helm install grafana grafana/grafana \
  --namespace monitoring \
  --set adminPassword='admin' \
  --set service.type=LoadBalancer
```

### Data Sources Configuration

#### Prometheus Data Source
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-datasources
  namespace: monitoring
data:
  prometheus.yml: |
    {
      "apiVersion": 1,
      "datasources": [
        {
          "name": "Prometheus",
          "type": "prometheus",
          "url": "http://prometheus-server.monitoring.svc.cluster.local",
          "access": "proxy",
          "isDefault": true
        },
        {
          "name": "Loki",
          "type": "loki",
          "url": "http://loki.monitoring.svc.cluster.local",
          "access": "proxy"
        },
        {
          "name": "Tempo",
          "type": "tempo",
          "url": "http://tempo.monitoring.svc.cluster.local",
          "access": "proxy"
        }
      ]
    }
```

#### PostgreSQL Data Source
```yaml
{
  "name": "PostgreSQL",
  "type": "postgres",
  "url": "postgres:5432",
  "database": "beie_nexus",
  "user": "${POSTGRES_USER}",
  "secureJsonData": {
    "password": "${POSTGRES_PASSWORD}"
  },
  "jsonData": {
    "sslmode": "require",
    "postgresVersion": 1500,
    "timescaledb": false
  }
}
```

## Core Dashboards

### Application Performance Dashboard

```json
{
  "dashboard": {
    "title": "BEIE Nexus - Application Performance",
    "tags": ["beie", "application"],
    "timezone": "Africa/Johannesburg",
    "panels": [
      {
        "title": "API Response Times",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{method!~\"(GET|POST|PUT|DELETE)\"}[5m]))",
            "legendFormat": "95th percentile"
          },
          {
            "expr": "histogram_quantile(0.50, rate(http_request_duration_seconds_bucket{method!~\"(GET|POST|PUT|DELETE)\"}[5m]))",
            "legendFormat": "50th percentile"
          }
        ]
      },
      {
        "title": "Error Rates",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m])) * 100",
            "legendFormat": "Error Rate %"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "mode": "absolute",
              "steps": [
                { "color": "green", "value": null },
                { "color": "orange", "value": 1 },
                { "color": "red", "value": 5 }
              ]
            }
          }
        }
      },
      {
        "title": "Throughput",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total[5m]))",
            "legendFormat": "Requests/sec"
          }
        ]
      }
    ]
  }
}
```

### Infrastructure Dashboard

```json
{
  "dashboard": {
    "title": "BEIE Nexus - Infrastructure Health",
    "tags": ["beie", "infrastructure"],
    "timezone": "Africa/Johannesburg",
    "panels": [
      {
        "title": "Kubernetes Pod Status",
        "type": "table",
        "targets": [
          {
            "expr": "kube_pod_container_status_running",
            "legendFormat": "{{namespace}}/{{pod}}"
          }
        ]
      },
      {
        "title": "Node CPU Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "{{instance}}"
          }
        ]
      },
      {
        "title": "Node Memory Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100",
            "legendFormat": "{{instance}}"
          }
        ]
      },
      {
        "title": "Disk Usage",
        "type": "bargauge",
        "targets": [
          {
            "expr": "(node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes * 100",
            "legendFormat": "{{mountpoint}}"
          }
        ]
      }
    ]
  }
}
```

### AI Performance Dashboard

```json
{
  "dashboard": {
    "title": "BEIE Nexus - AI Performance",
    "tags": ["beie", "ai"],
    "timezone": "Africa/Johannesburg",
    "panels": [
      {
        "title": "AI Agent Response Times",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(beie_ai_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          }
        ]
      },
      {
        "title": "AI Agent Success Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(rate(beie_ai_requests_total{status=\"success\"}[5m])) / sum(rate(beie_ai_requests_total[5m])) * 100",
            "legendFormat": "Success Rate %"
          }
        ]
      },
      {
        "title": "Token Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(beie_ai_tokens_total[5m]))",
            "legendFormat": "Tokens/min"
          }
        ]
      },
      {
        "title": "HITL Queue Depth",
        "type": "stat",
        "targets": [
          {
            "expr": "beie_ai_hitl_queue_length",
            "legendFormat": "Pending Reviews"
          }
        ]
      }
    ]
  }
}
```

### Business Metrics Dashboard

```json
{
  "dashboard": {
    "title": "BEIE Nexus - Business Metrics",
    "tags": ["beie", "business"],
    "timezone": "Africa/Johannesburg",
    "panels": [
      {
        "title": "Active Projects",
        "type": "stat",
        "targets": [
          {
            "expr": "beie_projects_active_total",
            "legendFormat": "Active Projects"
          }
        ]
      },
      {
        "title": "Monthly Revenue",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(beie_revenue_total[30d]))",
            "legendFormat": "Revenue ZAR"
          }
        ]
      },
      {
        "title": "Order Fulfillment Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(rate(beie_orders_completed_total[7d])) / sum(rate(beie_orders_created_total[7d])) * 100",
            "legendFormat": "Fulfillment %"
          }
        ]
      },
      {
        "title": "Customer Satisfaction",
        "type": "gauge",
        "targets": [
          {
            "expr": "avg(beie_customer_satisfaction_score)",
            "legendFormat": "CSAT Score"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "min": 0,
            "max": 5,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                { "color": "red", "value": 0 },
                { "color": "orange", "value": 3 },
                { "color": "green", "value": 4 }
              ]
            }
          }
        }
      }
    ]
  }
}
```

## Prometheus Configuration

### Core Metrics Collection

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - /etc/prometheus/alerting_rules.yml

scrape_configs:
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: kubernetes_pod_name

  - job_name: 'kubernetes-services'
    kubernetes_sd_configs:
      - role: service
    metrics_path: /metrics
    params:
      format: [prometheus]
    relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_service_name]
        action: replace
        target_label: kubernetes_service_name
```

### Application Metrics

#### NestJS Metrics
```typescript
// main.ts
import { PrometheusModule } from '@willsoto/nestjs-prometheus';

@Module({
  imports: [
    PrometheusModule.register({
      defaultMetrics: {
        enabled: true,
      },
      customMetrics: [
        {
          name: 'beie_http_requests_total',
          help: 'Total number of HTTP requests',
          labelNames: ['method', 'route', 'status_code'],
          type: 'counter',
        },
        {
          name: 'beie_http_request_duration_seconds',
          help: 'HTTP request duration in seconds',
          labelNames: ['method', 'route'],
          type: 'histogram',
          buckets: [0.1, 0.5, 1, 2.5, 5, 10],
        },
      ],
    }),
  ],
})
export class AppModule {}
```

#### Next.js Metrics
```typescript
// pages/api/metrics.ts
import { collectDefaultMetrics, register } from 'prom-client';

collectDefaultMetrics();

export default async function handler(req, res) {
  res.setHeader('Content-Type', register.contentType);
  res.send(await register.metrics());
}
```

## Alerting Rules

### Alert Manager Configuration

```yaml
# alertmanager.yml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@beie.co.za'
  smtp_auth_username: 'alerts@beie.co.za'
  smtp_auth_password: 'your-app-password'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'beie-alerts'
  routes:
    - match:
        severity: critical
      receiver: 'beie-critical'

receivers:
  - name: 'beie-alerts'
    email_configs:
      - to: 'devops@beie.co.za'
        subject: 'BEIE Nexus Alert: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Runbook: {{ .Annotations.runbook_url }}
          {{ end }}

  - name: 'beie-critical'
    pagerduty_configs:
      - service_key: 'your-pagerduty-integration-key'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#alerts'
        title: '🚨 Critical Alert'
        text: |
          {{ range .Alerts }}
          *{{ .Annotations.summary }}*
          {{ .Annotations.description }}
          <{{ .Annotations.runbook_url }}|Runbook>
          {{ end }}
```

### Alerting Rules

```yaml
# alerting_rules.yml
groups:
  - name: beie.application
    rules:
      - alert: HighErrorRate
        expr: sum(rate(http_requests_total{status=~"[5][0-9][0-9]"}[5m])) / sum(rate(http_requests_total[5m])) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value | printf \"%.2f\" }}% (threshold: 5%)"
          runbook_url: "https://docs.beie.co.za/runbooks/high-error-rate"

      - alert: SlowResponseTime
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Slow response times detected"
          description: "95th percentile response time is {{ $value | printf \"%.2f\" }}s (threshold: 2s)"

  - name: beie.infrastructure
    rules:
      - alert: PodCrashLooping
        expr: kube_pod_container_status_restarts_total > 5
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Pod crash looping"
          description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} has restarted {{ $value }} times"

      - alert: HighCPUUsage
        expr: (1 - rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100 > 80
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage"
          description: "CPU usage on {{ $labels.instance }} is {{ $value | printf \"%.1f\" }}%"

  - name: beie.business
    rules:
      - alert: LowOrderFulfillment
        expr: sum(rate(beie_orders_completed_total[1h])) / sum(rate(beie_orders_created_total[1h])) < 0.95
        for: 30m
        labels:
          severity: warning
        annotations:
          summary: "Low order fulfillment rate"
          description: "Order fulfillment rate is {{ $value | printf \"%.1f\" }}% (threshold: 95%)"
```

## Logging Configuration

### Loki Configuration

```yaml
# loki-config.yaml
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 5m
  chunk_retain_period: 30s

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /tmp/loki/index
    cache_location: /tmp/loki/cache
    shared_store: filesystem
  filesystem:
    directory: /tmp/loki/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: false
  retention_period: 0s
```

### Application Logging

#### Structured Logging in NestJS
```typescript
// logger.service.ts
import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class StructuredLogger extends Logger {
  log(message: any, context?: string) {
    super.log(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'info',
      message,
      context,
      service: 'api-gateway',
    }), context);
  }

  error(message: any, trace?: string, context?: string) {
    super.error(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'error',
      message,
      trace,
      context,
      service: 'api-gateway',
    }), trace, context);
  }
}
```

## Distributed Tracing

### Jaeger Configuration

```yaml
# jaeger-config.yml
service:
  extensions: [jaeger_storage, jaeger_query]
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [jaeger_storage]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [logging]

extensions:
  jaeger_storage:
    backends:
      memory:
        max_operations: 100000
  jaeger_query:
    storage:
      traces_backend: memory

receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024

exporters:
  jaeger_storage:
    trace_storage: jaeger_storage
  logging:
    loglevel: debug
```

### Tracing in Applications

#### NestJS Tracing
```typescript
// main.ts
import { JaegerExporter } from '@opentelemetry/exporter-jaeger';
import { SimpleSpanProcessor } from '@opentelemetry/sdk-trace-base';

const exporter = new JaegerExporter({
  endpoint: 'http://jaeger-collector.monitoring.svc.cluster.local:14268/api/traces',
});

const processor = new SimpleSpanProcessor(exporter);
```

#### Next.js Tracing
```javascript
// next.config.js
const { withSentry } = require('@sentry/nextjs');

module.exports = withSentry({
  // Sentry configuration
  sentry: {
    disableServerWebpackPlugin: true,
    disableClientWebpackPlugin: true,
  },
});
```

This monitoring dashboard configuration provides comprehensive observability for BEIE Nexus, enabling proactive issue detection and performance optimization.