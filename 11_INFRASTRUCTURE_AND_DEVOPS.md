# BEIE Nexus — Infrastructure, DevOps & Deployment
**Document:** INFRA-001 | **Version:** 1.0.0

---

## 1. Infrastructure Overview

### 1.1 Environment Matrix

| Environment | Purpose | Infrastructure | Domain |
|-------------|---------|---------------|--------|
| `local` | Individual developer | Docker Compose + Coolify local | localhost |
| `dev` | Feature integration | Coolify (1× VPS, 8 vCPU / 32GB) | dev.beie.co.za |
| `staging` | Pre-production | AWS EKS (small cluster) | staging.beie.co.za |
| `production` | Live | AWS EKS (HA cluster, af-south-1) | beie.co.za |

### 1.2 AWS Production Architecture

```
                    ┌─────────────────────────────────┐
                    │         Route 53 (DNS)           │
                    └─────────────┬───────────────────┘
                                  │
                    ┌─────────────▼───────────────────┐
                    │    Cloudflare (CDN + WAF)         │
                    │    - DDoS protection              │
                    │    - Static asset caching         │
                    │    - Bot management               │
                    └─────────────┬───────────────────┘
                                  │
              ┌───────────────────▼────────────────────────┐
              │          AWS Application Load Balancer       │
              │          (af-south-1, multi-AZ)              │
              └───┬──────────────────────────┬─────────────┘
                  │                          │
    ┌─────────────▼──────┐      ┌────────────▼────────────┐
    │  EKS Cluster        │      │  Supabase (Managed)      │
    │  af-south-1         │      │  PostgreSQL + Auth        │
    │                     │      │  + Storage + Realtime     │
    │  Node Groups:        │      └─────────────────────────┘
    │  - app: 3–10 nodes  │
    │  - ai: 1–4 nodes    │      ┌─────────────────────────┐
    │    (GPU-enabled)    │      │  MongoDB Atlas           │
    │  - system: 2 nodes  │      │  (af-south-1)            │
    └─────────────────────┘      └─────────────────────────┘

    Supporting Services:
    ┌───────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
    │ AWS S3    │  │ AWS SES  │  │ AWS SNS  │  │ AWS KMS  │
    │ (storage) │  │ (email)  │  │ (push/   │  │ (keys)   │
    └───────────┘  └──────────┘  │  SMS)    │  └──────────┘
                                 └──────────┘
    ┌───────────┐  ┌──────────┐  ┌──────────┐
    │ Upstash   │  │ Upstash  │  │ClickHouse│
    │ Redis     │  │ Kafka    │  │(analytics│
    └───────────┘  └──────────┘  └──────────┘
```

---

## 2. Kubernetes Configuration

### 2.1 Namespace Strategy

```yaml
# namespaces.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: beie-core        # Core application services
  labels:
    istio-injection: enabled
---
apiVersion: v1
kind: Namespace
metadata:
  name: beie-ai          # AI/ML services (GPU node group)
  labels:
    istio-injection: enabled
---
apiVersion: v1
kind: Namespace
metadata:
  name: beie-blockchain  # Blockchain services
  labels:
    istio-injection: enabled
---
apiVersion: v1
kind: Namespace
metadata:
  name: beie-monitoring  # Prometheus, Grafana, Jaeger
---
apiVersion: v1
kind: Namespace
metadata:
  name: beie-system      # Vault, cert-manager, cluster services
```

### 2.2 Standard Deployment Template

```yaml
# Standard deployment (example: api-gateway)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: beie-core
  labels:
    app: api-gateway
    version: v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-gateway
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0       # Zero-downtime deployments
  template:
    metadata:
      labels:
        app: api-gateway
        version: v1
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "3000"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: api-gateway-sa
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 1001
      containers:
        - name: api-gateway
          image: ghcr.io/beie/api-gateway:${VERSION}
          imagePullPolicy: Always
          ports:
            - containerPort: 3000
              name: http
          env:
            - name: NODE_ENV
              value: production
            - name: SUPABASE_URL
              valueFrom:
                secretKeyRef:
                  name: supabase-credentials
                  key: url
          resources:
            requests:
              cpu: "250m"
              memory: "256Mi"
            limits:
              cpu: "1000m"
              memory: "512Mi"
          readinessProbe:
            httpGet:
              path: /ready
              port: 3000
            initialDelaySeconds: 10
            periodSeconds: 5
            failureThreshold: 3
          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 30
            periodSeconds: 10
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: [ALL]
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: api-gateway
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-gateway-pdb
  namespace: beie-core
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: api-gateway
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-gateway-hpa
  namespace: beie-core
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-gateway
  minReplicas: 3
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 60
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 70
```

---

## 3. CI/CD Pipeline

### 3.1 Pipeline Architecture

```
Developer pushes to feature branch
    ↓
GitHub Actions Trigger
    ↓
┌──────────────────────────────────────────┐
│  Stage 1: Lint & Type Check (2 min)      │
│  - ESLint, Prettier, tsc --noEmit        │
│  - Clippy (Rust), go vet, mix credo      │
│  - Gitleaks (secret scanning)            │
└──────────────────┬───────────────────────┘
                   ↓
┌──────────────────────────────────────────┐
│  Stage 2: Unit Tests (5 min)             │
│  - Vitest, Jest, pytest, ExUnit          │
│  - Coverage gates enforced               │
│  - Parallel matrix execution             │
└──────────────────┬───────────────────────┘
                   ↓
┌──────────────────────────────────────────┐
│  Stage 3: Security Scan (3 min)          │
│  - Snyk (dependencies)                   │
│  - Trivy (container image)               │
│  - OWASP dependency check                │
└──────────────────┬───────────────────────┘
                   ↓
┌──────────────────────────────────────────┐
│  Stage 4: Build & Push (5 min)           │
│  - Docker buildx (multi-arch)            │
│  - Push to GHCR (GitHub Container Reg)   │
│  - Sign image with Cosign                │
└──────────────────┬───────────────────────┘
                   ↓
          [PR created/updated]
                   ↓
┌──────────────────────────────────────────┐
│  Stage 5: Deploy to Dev (auto, 3 min)    │
│  - Helm upgrade on Coolify               │
│  - Integration tests                     │
│  - Smoke tests                           │
└──────────────────┬───────────────────────┘
                   ↓
          [PR merged to main]
                   ↓
┌──────────────────────────────────────────┐
│  Stage 6: Deploy to Staging (auto)       │
│  - Helm upgrade on AWS EKS staging       │
│  - Full integration test suite           │
│  - E2E tests (Playwright)                │
│  - Performance tests (k6)                │
│  - DAST scan (OWASP ZAP)                 │
└──────────────────┬───────────────────────┘
                   ↓
          [Manual approval gate]
                   ↓
┌──────────────────────────────────────────┐
│  Stage 7: Deploy to Production           │
│  - Blue-green deployment                 │
│  - Canary: 5% → 20% → 50% → 100%        │
│  - Automated rollback on error rate > 1% │
│  - Post-deploy smoke tests               │
└──────────────────────────────────────────┘
```

### 3.2 GitHub Actions — Core Workflow

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, staging]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_PREFIX: ghcr.io/beie

jobs:
  affected:
    runs-on: ubuntu-latest
    outputs:
      services: ${{ steps.affected.outputs.services }}
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - name: Determine affected services
        id: affected
        run: |
          # Turborepo affected detection
          echo "services=$(pnpm turbo run build --dry=json | jq -c '[.tasks[].taskId]')" >> $GITHUB_OUTPUT

  lint:
    needs: affected
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v3
      - uses: actions/setup-node@v4
        with: { node-version: '22', cache: 'pnpm' }
      - run: pnpm install --frozen-lockfile
      - run: pnpm turbo run lint type-check --affected
      - name: Gitleaks scan
        uses: gitleaks/gitleaks-action@v2

  test:
    needs: lint
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: ${{ fromJson(needs.affected.outputs.services) }}
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v3
      - run: pnpm install --frozen-lockfile
      - run: pnpm turbo run test --filter=${{ matrix.service }}
      - name: Upload coverage
        uses: codecov/codecov-action@v4

  security:
    needs: lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Snyk scan
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high

  build:
    needs: [test, security]
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      id-token: write
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          push: true
          tags: ${{ env.IMAGE_PREFIX }}/api-gateway:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          provenance: true
          sbom: true
      - name: Sign image with Cosign
        uses: sigstore/cosign-installer@v3
      - run: cosign sign --yes ${{ env.IMAGE_PREFIX }}/api-gateway:${{ github.sha }}

  deploy-dev:
    needs: build
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    environment: development
    steps:
      - name: Deploy to Coolify (dev)
        run: |
          curl -X POST ${{ secrets.COOLIFY_WEBHOOK_URL }} \
            -H "Authorization: Bearer ${{ secrets.COOLIFY_TOKEN }}" \
            -d '{"service": "api-gateway", "tag": "${{ github.sha }}"}'

  deploy-production:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://beie.co.za
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE }}
          aws-region: af-south-1
      - name: Update kubeconfig
        run: aws eks update-kubeconfig --name beie-production --region af-south-1
      - name: Helm upgrade (canary start)
        run: |
          helm upgrade api-gateway ./charts/api-gateway \
            --namespace beie-core \
            --set image.tag=${{ github.sha }} \
            --set canary.weight=5 \
            --wait --timeout 5m
```

---

## 4. Coolify Configuration (Dev/Staging Self-Hosted)

### 4.1 Docker Compose (Local Development)

```yaml
# docker-compose.yml (local dev)
version: '3.9'

services:
  api-gateway:
    build: ./apps/api-gateway
    ports: ["3000:3000"]
    environment:
      - NODE_ENV=development
      - DATABASE_URL=${DATABASE_URL}
    volumes:
      - ./apps/api-gateway/src:/app/src  # Hot reload
    depends_on:
      - redis
      - kafka

  web-public:
    build: ./apps/web-public
    ports: ["3001:3000"]
    volumes:
      - ./apps/web-public/src:/app/src
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:3000

  web-dashboard:
    build: ./apps/web-dashboard
    ports: ["4200:80"]
    volumes:
      - ./apps/web-dashboard/src:/app/src

  service-chat:
    build: ./apps/service-chat
    ports: ["4000:4000"]
    environment:
      - DATABASE_URL=${SUPABASE_URL}
      - SECRET_KEY_BASE=${ELIXIR_SECRET}

  service-ai:
    build: ./apps/service-ai
    ports: ["8000:8000"]
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
    deploy:
      resources:
        limits:
          memory: 4G

  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]
    volumes:
      - redis_data:/data

  kafka:
    image: confluentinc/cp-kafka:7.6.0
    ports: ["9092:9092"]
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"
      KAFKA_NUM_PARTITIONS: 3
      KAFKA_DEFAULT_REPLICATION_FACTOR: 1

  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    ports: ["8080:8080"]
    environment:
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:9092

volumes:
  redis_data:
```

---

## 5. Monitoring & Observability Stack

### 5.1 Grafana Dashboards (Required)

| Dashboard | Metrics Source | Refresh |
|-----------|---------------|---------|
| Platform Overview | Prometheus | 30s |
| API Gateway Performance | Prometheus | 10s |
| Business KPIs | Supabase + ClickHouse | 5min |
| AI Agent Performance | Prometheus + ClickHouse | 1min |
| Blockchain Anchor Status | Custom exporter | 1min |
| Error Budget & SLO | Prometheus | 1min |
| Database Performance | Supabase metrics | 1min |
| Security Events | Audit log | 1min |

### 5.2 Alerting Rules

```yaml
# alerting-rules.yaml (Prometheus)
groups:
  - name: beie.slo
    rules:
      - alert: APIHighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m])) /
          sum(rate(http_requests_total[5m])) > 0.01
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "API error rate above 1% SLO"

      - alert: HighLatency
        expr: |
          histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 0.5
        for: 5m
        labels:
          severity: warning

      - alert: AIAgentHighEscalationRate
        expr: |
          sum(rate(beie_ai_tasks_total{status="escalated"}[30m])) /
          sum(rate(beie_ai_tasks_total[30m])) > 0.6
        for: 5m
        labels:
          severity: warning

      - alert: BlockchainAnchorFailing
        expr: |
          sum(rate(beie_blockchain_anchors_total{status="failed"}[10m])) > 0
        for: 1m
        labels:
          severity: critical
```

### 5.3 On-Call Rotation

| Severity | Notification | Response |
|----------|-------------|---------|
| P0 (Critical) | PagerDuty immediate + SMS | 15 min |
| P1 (High) | PagerDuty + Slack #alerts | 1 hour |
| P2 (Medium) | Slack #alerts | 4 hours |
| P3 (Low) | Jira ticket created | Next business day |

---

## 6. Terraform — Key Resources

```hcl
# infrastructure/terraform/main.tf

terraform {
  required_version = ">= 1.8"
  backend "s3" {
    bucket         = "beie-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "af-south-1"
    encrypt        = true
    dynamodb_table = "beie-terraform-locks"
  }
  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 5.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.0" }
    helm       = { source = "hashicorp/helm", version = "~> 2.0" }
    vault      = { source = "hashicorp/vault", version = "~> 3.0" }
  }
}

# EKS Cluster
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.0"
  cluster_name    = "beie-production"
  cluster_version = "1.30"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  eks_managed_node_groups = {
    app = {
      min_size       = 3
      max_size       = 10
      instance_types = ["m6i.xlarge"]  # 4 vCPU, 16GB
      capacity_type  = "ON_DEMAND"
    }
    ai = {
      min_size       = 0
      max_size       = 4
      instance_types = ["g4dn.xlarge"]  # GPU for AI inference
      capacity_type  = "SPOT"           # Cost optimisation
      taints = [{
        key    = "nvidia.com/gpu"
        effect = "NO_SCHEDULE"
      }]
    }
  }
}

# VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0"
  name    = "beie-production"
  cidr    = "10.0.0.0/16"
  azs     = ["af-south-1a", "af-south-1b", "af-south-1c"]
  
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets   = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  enable_nat_gateway     = true
  single_nat_gateway     = false    # HA: one per AZ
  enable_dns_hostnames   = true
  enable_dns_support     = true
}
```

---

*Infrastructure changes require a Terraform plan review by at least one senior engineer before apply. Production applies require two approvals.*
