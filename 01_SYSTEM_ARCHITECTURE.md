# BEIE Nexus Platform — Master System Architecture
**Document:** ARCH-001 | **Version:** 1.0.0 | **Status:** Canonical Reference  
**Classification:** Internal Engineering · Confidential  
**Owner:** BEIE CTO / Principal Architect  

---

## 1. System Identity

**Product Name:** BEIE Nexus  
**Tagline:** The Singularity Orchestration Platform for Electrical & Instrumentation Engineering  
**Mission:** To digitise, automate, and blockchain-anchor every workflow in the South African built environment E&I sector — from product sales to project delivery to compliance certification.

---

## 2. Architecture Philosophy

### 2.1 Core Principles

| Principle | Implementation |
|-----------|---------------|
| **Domain Isolation** | Each bounded context is an autonomous service with its own data store |
| **Event Sourcing** | All state changes are events; state is derived, never mutated in place |
| **Blockchain Auditability** | Every compliance, financial, and milestone event is hashed to Polygon CDK |
| **AI-First Workflows** | Every human workflow has an AI-augmented counterpart |
| **Human-in-the-Loop** | No agentic decision affecting money, compliance, or clients executes without human approval gate |
| **Zero-Trust Security** | Every service call is authenticated; no implicit trust between services |
| **Progressive Enhancement** | UI degrades gracefully from 4K TV to feature phone |

### 2.2 Architectural Patterns

- **CQRS** (Command Query Responsibility Segregation) across all domains
- **Event-Driven Architecture** via Kafka/Upstash Kafka
- **Hexagonal Architecture** (Ports & Adapters) per service
- **Saga Pattern** for distributed transactions
- **Outbox Pattern** for guaranteed event delivery
- **BFF Pattern** (Backend for Frontend) per client type

---

## 3. System Layers

```
┌─────────────────────────────────────────────────────────────────────┐
│  LAYER 7 — CLIENT LAYER                                             │
│  Next.js (Public Web) · Angular (Dashboard/ERP) · React Native      │
│  (Mobile) · TV App (React Native TV) · Embedded (IoT firmware C++)  │
├─────────────────────────────────────────────────────────────────────┤
│  LAYER 6 — API GATEWAY & BFF                                        │
│  NestJS API Gateway · GraphQL Federation · REST · WebSocket         │
│  Rate limiting · Auth · Request routing · Circuit breaker           │
├─────────────────────────────────────────────────────────────────────┤
│  LAYER 5 — APPLICATION SERVICES                                     │
│  NestJS Microservices · Go Services · Elixir/Phoenix (Real-time)    │
│  Kotlin/Java (ERP Core) · Python (AI Orchestration)                 │
├─────────────────────────────────────────────────────────────────────┤
│  LAYER 4 — DOMAIN INTELLIGENCE                                      │
│  LangGraph (Workflow AI) · CrewAI (Multi-Agent) · LlamaIndex (RAG)  │
│  Claude API · Anthropic (Primary LLM) · Embedding Models            │
├─────────────────────────────────────────────────────────────────────┤
│  LAYER 3 — DATA LAYER                                               │
│  Supabase (PostgreSQL + Auth + Storage + Realtime)                  │
│  MongoDB Atlas (Catalogue + Unstructured) · Upstash Redis           │
│  ClickHouse (Analytics) · Pinecone/pgvector (Vector)                │
├─────────────────────────────────────────────────────────────────────┤
│  LAYER 2 — BLOCKCHAIN AUDIT LAYER                                   │
│  Polygon CDK (L2 Chain) · Rust Bridge Service                       │
│  Smart Contracts (Solidity) · IPFS (Document anchoring)             │
├─────────────────────────────────────────────────────────────────────┤
│  LAYER 1 — INFRASTRUCTURE                                           │
│  AWS (Primary Cloud) · Coolify (Self-hosted orchestration)          │
│  Cloudflare (CDN + WAF + DDoS) · Terraform (IaC)                    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 4. Domain Map (Bounded Contexts)

### 4.1 Primary Domains

```
BEIE Nexus
├── 01. Identity & Access (IAM)
├── 02. Corporate Website (Public)
├── 03. E-Commerce Platform
│   ├── Product Catalogue
│   ├── Inventory Management
│   ├── Pricing Engine
│   ├── Order Management
│   └── Supplier Portal
├── 04. Project Management
│   ├── Project Lifecycle
│   ├── Gantt & Scheduling
│   ├── Resource Management
│   ├── Document Control
│   └── Site Management
├── 05. Client Portal
│   ├── Client Dashboard
│   ├── Project Tracking
│   ├── Invoice & Payment
│   ├── Document Repository
│   └── Support Ticketing
├── 06. ERP Core
│   ├── Financial Management
│   ├── Procurement
│   ├── Inventory & Warehouse
│   ├── HR & Payroll
│   ├── Asset Management
│   └── Compliance Management
├── 07. Communication Platform (Nexus Chat)
│   ├── Channels & Threads
│   ├── Direct Messaging
│   ├── Video Conferencing
│   ├── File Sharing
│   └── Bot Integration
├── 08. AI Orchestration Engine
│   ├── Workflow Agents
│   ├── Compliance Checker
│   ├── Estimating Agent
│   ├── Document Generator
│   └── Predictive Maintenance
├── 09. Blockchain Audit (Nexus Chain)
│   ├── Event Anchoring
│   ├── Certificate Registry
│   ├── SLA Verification
│   └── Payment Escrow
├── 10. Analytics & Reporting
│   ├── Operations Dashboard
│   ├── Financial Intelligence
│   ├── Client Analytics
│   └── AI-generated Reports
└── 11. IoT & Field Integration
    ├── Device Management
    ├── Telemetry Ingestion
    ├── Alert Engine
    └── Maintenance Triggers
```

---

## 5. Technology Stack — Authoritative Reference

### 5.1 Frontend

| Technology | Role | Version Target |
|------------|------|----------------|
| Next.js 15 | Public website, marketing, SEO, e-commerce storefront | 15.x |
| Angular 19 | ERP dashboard, client portal, project management UI | 19.x |
| TypeScript | All frontend code, strict mode enforced | 5.x |
| Tailwind CSS | Design system base, utility classes | 4.x |
| shadcn/ui | Component library (Next.js layer) | Latest |
| Angular Material + CDK | Component library (Angular layer) | 19.x |
| Framer Motion | Animation (Next.js) | 12.x |
| Angular Animations | Animation (Angular layer) | Native |
| RxJS | Reactive state (Angular) | 7.x |
| Zustand | Global state (Next.js) | 5.x |
| TanStack Query | Server state, caching | 5.x |
| Socket.io Client | Real-time updates | 4.x |
| Three.js | 3D visualisations (site maps, dashboards) | Latest |
| D3.js | Data visualisation, charts | 7.x |
| PWA | Progressive web app manifest | Native |

### 5.2 Backend Services

| Technology | Service | Rationale |
|------------|---------|-----------|
| NestJS + TypeScript | API Gateway, BFF, Core Services | TypeScript consistency, enterprise patterns |
| Go 1.23 | Real-time notification service, file processing, search | High throughput, low latency |
| Elixir 1.17 / Phoenix 1.7 | Nexus Chat (communication platform) | Purpose-built for concurrent real-time |
| Python 3.12 | AI Orchestration Engine | LangGraph/CrewAI ecosystem |
| Kotlin 2.0 / Spring Boot 3 | ERP Core (Finance, HR, Procurement) | JVM reliability, enterprise libraries |
| Java 21 | Reporting engine, batch processing | Long-term stability |
| Rust 1.80 | Blockchain bridge, crypto, performance pipelines | Memory safety, performance |
| C++ 23 | IoT firmware, embedded field devices | Hardware interface |
| Solidity 0.8.x | Polygon CDK smart contracts | Blockchain audit layer |

### 5.3 Deferred Languages (Phase 3+)

| Technology | Planned Use | Phase |
|------------|-------------|-------|
| Julia 1.11 | Engineering calculation engine, load analysis | Phase 3 |
| Mojo | AI inference acceleration | Phase 3 |
| Gleam | Type-safe functional microservices | Phase 4 |
| Crystal | High-performance scripting services | Phase 4 |
| Vlang | Build tooling, CLI tools | Phase 3 |
| Zig | Low-level system tools, IoT cross-compilation | Phase 3 |

### 5.4 Data Infrastructure

| Technology | Role |
|------------|------|
| Supabase (PostgreSQL 16) | Primary relational store, auth, storage, realtime |
| MongoDB Atlas | Product catalogue, unstructured documents, logs |
| Upstash Redis | Caching, sessions, rate limiting, pub/sub |
| Upstash Kafka | Event streaming, async messaging |
| ClickHouse | Analytics, time-series, reporting queries |
| pgvector (Supabase) | Vector embeddings for RAG |
| IPFS / Filecoin | Immutable document storage (compliance records) |

### 5.5 AI/ML Stack

| Technology | Role |
|------------|------|
| Anthropic Claude API | Primary reasoning, generation, analysis |
| LangGraph | Stateful workflow orchestration |
| LangChain | Tool chains, document processing |
| CrewAI | Multi-agent task delegation |
| LlamaIndex | RAG over product catalogue and documents |
| Sentence Transformers | Embedding generation |
| Whisper | Voice-to-text for field notes |
| Instructor | Structured LLM outputs |

### 5.6 Infrastructure & DevOps

| Technology | Role |
|------------|------|
| AWS (Primary) | EKS, RDS, S3, CloudFront, SES, SNS, Route53 |
| Coolify | Self-hosted orchestration, dev/staging environments |
| Cloudflare | CDN, WAF, DDoS protection, Workers, R2 |
| Terraform | Infrastructure as Code |
| Kubernetes (EKS) | Production container orchestration |
| Docker | Containerisation |
| GitHub Actions | CI/CD pipelines |
| Prometheus + Grafana | Monitoring and alerting |
| Jaeger | Distributed tracing |
| Vault (HashiCorp) | Secrets management |
| Polygon CDK | Permissioned L2 blockchain |

---

## 6. Data Architecture

### 6.1 Database Ownership by Domain

| Domain | Primary Store | Secondary |
|--------|--------------|-----------|
| IAM | Supabase (Auth) | Redis (sessions) |
| E-Commerce Catalogue | MongoDB Atlas | pgvector (search) |
| Orders & Transactions | Supabase (PostgreSQL) | Kafka (events) |
| Project Management | Supabase (PostgreSQL) | Redis (live state) |
| Communication | Supabase (PostgreSQL) | Redis (presence) |
| ERP — Finance | Supabase (PostgreSQL) | ClickHouse (reporting) |
| ERP — HR/Payroll | Supabase (PostgreSQL) | Encrypted at rest |
| AI Conversations | MongoDB Atlas | pgvector |
| Blockchain Records | Polygon CDK | IPFS |
| Analytics | ClickHouse | — |
| IoT Telemetry | ClickHouse | Kafka (ingestion) |

### 6.2 Event Schema Standard

All events must conform to:
```typescript
interface NexusEvent {
  id: string;           // UUID v7
  type: string;         // domain.entity.action (e.g., project.milestone.completed)
  version: string;      // semver
  timestamp: string;    // ISO 8601
  tenantId: string;     // Multi-tenancy
  actorId: string;      // User or agent who triggered
  aggregateId: string;  // Entity ID
  aggregateType: string;
  payload: Record<string, unknown>;
  metadata: {
    correlationId: string;
    causationId: string;
    ipAddress?: string;
    userAgent?: string;
  };
  blockchainRef?: string; // Polygon CDK tx hash (post-anchor)
}
```

---

## 7. Security Architecture

### 7.1 Security Layers

```
Internet → Cloudflare WAF → AWS ALB → Istio Service Mesh → Service
```

1. **Cloudflare WAF** — DDoS mitigation, bot protection, geo-blocking, rate limiting at edge
2. **AWS WAF** — L7 rules, OWASP top 10, custom rules
3. **TLS 1.3** — All traffic encrypted in transit, mutual TLS between services
4. **Istio** — Service mesh, mTLS, traffic policies, zero-trust inter-service
5. **Vault** — Dynamic secrets, PKI, encryption as a service
6. **Supabase RLS** — Row-Level Security on every database table

### 7.2 Authentication & Authorisation

- **Supabase Auth** — Primary auth (email/password, OAuth, magic link, OTP)
- **JWT** — Short-lived access tokens (15 min), rotating refresh tokens (7 days)
- **RBAC** — Role-Based Access Control with 8 system roles
- **ABAC** — Attribute-Based Access Control for fine-grained resource access
- **MFA** — Mandatory for admin roles, optional for standard users
- **API Keys** — For programmatic/IoT access, scoped and rotatable

### 7.3 System Roles

| Role | Scope |
|------|-------|
| `super_admin` | Full platform access |
| `tenant_admin` | Full access within tenant |
| `project_manager` | Projects, resources, reports |
| `engineer` | Assigned projects, technical documents |
| `technician` | Field assignments, job cards |
| `finance` | Financial modules, invoicing |
| `client` | Client portal only |
| `vendor` | Supplier portal only |

### 7.4 Data Security

- All PII encrypted at rest using AES-256
- Supabase column-level encryption for sensitive fields
- Audit log for every data access event
- GDPR/POPIA compliance — data residency in South Africa (AWS af-south-1)
- Automated PII detection and masking in logs

---

## 8. Blockchain Architecture (Nexus Chain)

### 8.1 What Gets Anchored

| Event Type | Trigger | Smart Contract |
|------------|---------|---------------|
| Project milestone completion | PM approves milestone | `ProjectRegistry.sol` |
| CoC issuance | Engineer signs off | `ComplianceRegistry.sol` |
| SLA breach/resolution | System detects + PM confirms | `SLARegistry.sol` |
| Invoice issued | Finance approves | `FinancialRegistry.sol` |
| Payment received | Payment gateway confirms | `FinancialRegistry.sol` |
| Material procurement | PO approved | `ProcurementRegistry.sol` |
| AI agent decision | Agent acts on workflow | `AgentAuditLog.sol` |

### 8.2 Anchoring Flow

```
Business Event
    → Supabase Event (source of truth)
    → Kafka Topic
    → Rust Bridge Service (hashes payload, signs with service key)
    → Polygon CDK Transaction
    → IPFS (full document if applicable)
    → Blockchain ref stored back in Supabase record
    → Client-visible verification link
```

### 8.3 Smart Contract Standards

- All contracts use OpenZeppelin base contracts
- Upgradeable via transparent proxy pattern
- Multi-sig governance (3-of-5) for contract upgrades
- Events emitted for all state changes
- Formal verification using Certora (Phase 2)

---

## 9. AI Orchestration Architecture

### 9.1 Agent Roster

| Agent | Framework | Capability |
|-------|-----------|-----------|
| `EstimatingAgent` | LangGraph | Generates project quotes from scope descriptions |
| `ComplianceAgent` | LangGraph | Checks designs against SANS standards, flags issues |
| `TenderAgent` | CrewAI | Multi-agent tender document preparation |
| `MaintenanceAgent` | LangGraph | Analyses IoT telemetry, predicts failures |
| `FinanceAgent` | LangGraph | Cash flow analysis, payment risk scoring |
| `DocumentAgent` | LangChain + LlamaIndex | Generates reports, extracts data from uploads |
| `CatalogueAgent` | LlamaIndex | Product recommendations, spec matching |
| `SupportAgent` | LangGraph | Client support, escalation routing |
| `SchedulingAgent` | LangGraph | Resource allocation, schedule optimisation |

### 9.2 Human-in-the-Loop Gates

Every agent workflow has defined HITL gates:

```
Agent proposes action
    → Confidence score calculated
    → If confidence < 0.85: mandatory human review
    → If action type in [financial, compliance, client-facing]: always human review
    → Human approves/rejects/modifies
    → Agent proceeds or replans
    → Full audit trail on blockchain
```

---

## 10. Infrastructure Topology

### 10.1 Environments

| Environment | Infrastructure | Purpose |
|-------------|---------------|---------|
| `local` | Docker Compose + Coolify | Developer machines |
| `dev` | Coolify (self-hosted VPS) | Feature development |
| `staging` | AWS (scaled-down EKS) | Pre-production testing |
| `production` | AWS EKS (af-south-1) | Live system |

### 10.2 AWS Services Used

- **EKS** — Kubernetes cluster (production)
- **RDS** — PostgreSQL backup (Supabase primary)
- **S3** — Object storage, backups, static assets
- **CloudFront** — CDN for static assets
- **SES** — Transactional email
- **SNS** — Push notifications, SMS
- **Route 53** — DNS management
- **ACM** — TLS certificates
- **KMS** — Key management
- **Secrets Manager** — Runtime secrets
- **CloudWatch** — Log aggregation
- **af-south-1** — Cape Town region (data sovereignty)

---

## 11. Scalability Strategy

### 11.1 Horizontal Scaling Targets

| Service | Min Pods | Max Pods | Scale Trigger |
|---------|---------|---------|---------------|
| API Gateway | 3 | 20 | CPU > 60% |
| E-Commerce | 2 | 15 | RPS > 500 |
| Chat (Elixir) | 2 | 10 | Connections > 5,000 |
| AI Orchestration | 1 | 8 | Queue depth > 20 |
| Blockchain Bridge | 2 | 5 | Queue depth > 50 |

### 11.2 Performance Targets

| Metric | Target |
|--------|--------|
| API P95 latency | < 200ms |
| Page load (LCP) | < 2.5s |
| Chat message delivery | < 100ms |
| Search results | < 500ms |
| Report generation | < 30s |
| Uptime SLA | 99.9% |

---

*Document ends. See companion documents for domain-specific specifications.*
