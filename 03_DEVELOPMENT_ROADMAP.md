# BEIE Nexus — Development Roadmap
**Document:** ROAD-001 | **Version:** 1.0.0 | **Status:** Active  
**Planning Horizon:** 18 Months (Q2 2026 – Q4 2027)

---

## Roadmap Philosophy

Development proceeds in phases, each delivering standalone value. No phase begins until the previous phase's acceptance criteria are met and signed off by the BEIE product owner. Each sprint is 2 weeks. Each phase contains multiple sprints.

---

## Phase 0 — Foundation (Weeks 1–4)
**Goal:** Infrastructure, DevOps pipeline, and core architecture ready for development.  
**Team:** 1 DevOps/Infra Engineer, 1 Architect

### Deliverables

| # | Deliverable | Owner | Week |
|---|-------------|-------|------|
| 0.1 | AWS account setup, IAM policies, af-south-1 region configured | DevOps | 1 |
| 0.2 | Coolify self-hosted environment (dev + staging) | DevOps | 1 |
| 0.3 | GitHub organisation, branch strategy, repo structure | Architect | 1 |
| 0.4 | Supabase project setup, RLS policies template | Architect | 2 |
| 0.5 | MongoDB Atlas cluster, network config | DevOps | 2 |
| 0.6 | Upstash Redis + Kafka provisioned | DevOps | 2 |
| 0.7 | Cloudflare zones, WAF rules baseline | DevOps | 2 |
| 0.8 | CI/CD pipelines (GitHub Actions): lint, test, build, deploy | DevOps | 3 |
| 0.9 | Terraform IaC for all environments | DevOps | 3 |
| 0.10 | HashiCorp Vault setup, secrets baseline | DevOps | 3 |
| 0.11 | Monitoring stack: Prometheus + Grafana + Jaeger | DevOps | 4 |
| 0.12 | Polygon CDK node setup, test network | Blockchain Eng | 4 |
| 0.13 | Developer onboarding documentation | Architect | 4 |

### Acceptance Criteria
- [ ] All environments reachable and healthy
- [ ] Secrets never in code repositories (verified by Gitleaks scan)
- [ ] CI pipeline runs in < 10 minutes
- [ ] Developer can spin up full local stack in < 15 minutes

---

## Phase 1 — Core Platform (Weeks 5–20)
**Goal:** Corporate website live, e-commerce functional, client portal operational, project management foundation.  
**Team:** 3 Full-stack, 1 Frontend Specialist, 1 Backend Specialist, 1 AI Engineer

### Sprint 1–2 (Weeks 5–8): Identity & Corporate Website

| # | Deliverable | Tech | Priority |
|---|-------------|------|----------|
| 1.1 | IAM service: auth, RBAC, multi-tenancy | NestJS + Supabase Auth | P0 |
| 1.2 | Corporate website (port from HTML prototype) | Next.js 15 | P0 |
| 1.3 | Design system: tokens, components, Storybook | Tailwind + shadcn | P0 |
| 1.4 | Email service integration (SES) | NestJS | P1 |
| 1.5 | CMS for website content (Sanity.io) | Next.js + Sanity | P1 |
| 1.6 | SEO foundation: sitemaps, metadata, OG tags | Next.js | P1 |
| 1.7 | Contact/quote form backend | NestJS | P0 |

### Sprint 3–4 (Weeks 9–12): E-Commerce Foundation

| # | Deliverable | Tech | Priority |
|---|-------------|------|----------|
| 1.8 | Product catalogue data model & MongoDB schema | MongoDB | P0 |
| 1.9 | Product catalogue API (search, filter, paginate) | NestJS | P0 |
| 1.10 | Product catalogue UI: listing, detail, search | Next.js | P0 |
| 1.11 | Pricing engine (standard, client-tier, bulk) | NestJS | P0 |
| 1.12 | Shopping cart (Redis-backed) | Next.js + Redis | P0 |
| 1.13 | Checkout flow UI | Next.js | P1 |
| 1.14 | Payment gateway: Peach Payments (ZA-first) + Stripe | NestJS | P0 |
| 1.15 | Order management service | NestJS | P0 |
| 1.16 | Product image handling (Cloudflare R2 + optimisation) | Go | P1 |
| 1.17 | Inventory tracking (basic) | NestJS + Supabase | P1 |

### Sprint 5–6 (Weeks 13–16): Project Management Core

| # | Deliverable | Tech | Priority |
|---|-------------|------|----------|
| 1.18 | Project domain model (projects, phases, tasks, milestones) | NestJS | P0 |
| 1.19 | Project dashboard (Monday.com-inspired) | Angular | P0 |
| 1.20 | Kanban board view | Angular + CDK | P0 |
| 1.21 | Gantt chart view | Angular + D3 | P1 |
| 1.22 | Task management (assign, deadline, status, subtasks) | Angular + NestJS | P0 |
| 1.23 | File attachment system (Supabase Storage) | NestJS | P0 |
| 1.24 | Project timeline & milestone tracking | Angular | P0 |
| 1.25 | Resource assignment engine | NestJS | P1 |
| 1.26 | Real-time project updates (WebSocket) | Go + Socket.io | P0 |

### Sprint 7–8 (Weeks 17–20): Client Portal

| # | Deliverable | Tech | Priority |
|---|-------------|------|----------|
| 1.27 | Client portal shell (separate Angular app) | Angular | P0 |
| 1.28 | Client project view (read-only progress) | Angular | P0 |
| 1.29 | Document repository (download CoCs, drawings, reports) | Angular + Supabase | P0 |
| 1.30 | Invoice viewing and payment | Angular + Peach | P0 |
| 1.31 | Support ticket system | Angular + NestJS | P1 |
| 1.32 | Client notifications (email + in-app) | NestJS + SES | P0 |
| 1.33 | Client onboarding flow | Angular | P1 |

### Phase 1 Acceptance Criteria
- [ ] Website live at beie.co.za with < 2.5s LCP
- [ ] E-commerce: add to cart → checkout → order confirmation flow working
- [ ] Project manager can create project, assign tasks, track milestones
- [ ] Client can log in and view their project status and documents
- [ ] All payment flows tested against Peach Payments sandbox

---

## Phase 2 — Communication, ERP & AI (Weeks 21–36)
**Goal:** Nexus Chat operational, ERP core modules live, first AI agents deployed.

### Sprint 9–11 (Weeks 21–26): Nexus Chat (Communication Platform)

| # | Deliverable | Tech | Priority |
|---|-------------|------|----------|
| 2.1 | Elixir/Phoenix application setup | Elixir + Phoenix | P0 |
| 2.2 | Channel architecture (workspaces, channels, threads) | Elixir | P0 |
| 2.3 | Real-time messaging with presence | Phoenix Channels | P0 |
| 2.4 | Direct messaging | Elixir | P0 |
| 2.5 | File sharing in chat (images, PDFs, drawings) | Elixir + S3 | P1 |
| 2.6 | Message search (full-text) | Go + Elasticsearch | P1 |
| 2.7 | Notification bridge (chat → email/push) | NestJS | P0 |
| 2.8 | Chat UI embedded in Angular dashboard | Angular + Phoenix WS | P0 |
| 2.9 | @mentions, reactions, thread replies | Elixir | P1 |
| 2.10 | Bot integration framework (for AI agents) | Elixir | P1 |

### Sprint 12–14 (Weeks 27–32): ERP Core

| # | Deliverable | Tech | Priority |
|---|-------------|------|----------|
| 2.11 | Chart of accounts, journal entries | Kotlin + Spring Boot | P0 |
| 2.12 | Invoice generation engine | Kotlin | P0 |
| 2.13 | Accounts receivable / payable | Kotlin | P0 |
| 2.14 | Purchase order management | Kotlin | P0 |
| 2.15 | Supplier management | Kotlin + NestJS | P1 |
| 2.16 | HR module: employee records, leave management | Kotlin | P0 |
| 2.17 | Payroll engine (PAYE, UIF, SDL — South African compliance) | Kotlin | P0 |
| 2.18 | Asset register (fleet, equipment) | NestJS | P0 |
| 2.19 | ClickHouse analytics pipeline setup | Go | P1 |
| 2.20 | Financial dashboard | Angular | P0 |

### Sprint 15–16 (Weeks 33–36): First AI Agents

| # | Deliverable | Tech | Priority |
|---|-------------|------|----------|
| 2.21 | AI Orchestration service setup | Python + FastAPI | P0 |
| 2.22 | EstimatingAgent v1 (quote from project scope) | LangGraph | P0 |
| 2.23 | DocumentAgent v1 (generate reports, extract data) | LangChain | P0 |
| 2.24 | SupportAgent v1 (client support drafts) | LangGraph | P1 |
| 2.25 | CatalogueAgent v1 (product search & recommend) | LlamaIndex | P0 |
| 2.26 | HITL approval UI (review agent outputs) | Angular | P0 |
| 2.27 | Agent audit dashboard | Angular + ClickHouse | P1 |
| 2.28 | RAG pipeline for product catalogue | LlamaIndex + pgvector | P0 |

---

## Phase 3 — Blockchain, Advanced AI & IoT (Weeks 37–52)
**Goal:** Polygon CDK audit layer live, advanced agents, IoT integration.

### Key Deliverables

| # | Deliverable | Tech | Week |
|---|-------------|------|------|
| 3.1 | Polygon CDK mainnet deployment | Solidity + Rust | 37–40 |
| 3.2 | Smart contracts: ProjectRegistry, ComplianceRegistry | Solidity | 37–40 |
| 3.3 | Rust blockchain bridge service | Rust | 41–42 |
| 3.4 | IPFS integration for document anchoring | Rust | 42–43 |
| 3.5 | ComplianceAgent v1 (SANS 10142-1 checker) | LangGraph | 44–45 |
| 3.6 | TenderAgent v1 (CrewAI multi-agent) | CrewAI | 45–47 |
| 3.7 | MaintenanceAgent v1 (IoT telemetry analysis) | LangGraph | 47–48 |
| 3.8 | IoT device management platform | Go | 48–50 |
| 3.9 | Telemetry ingestion pipeline (ClickHouse) | Go + Kafka | 49–50 |
| 3.10 | Predictive maintenance dashboard | Angular + D3 | 51–52 |
| 3.11 | Julia calculation engine (load analysis) | Julia | 50–52 |
| 3.12 | Vlang CLI tooling for field technicians | Vlang | 51–52 |

---

## Phase 4 — Intelligence & Scale (Weeks 53–72)
**Goal:** Full ML-driven platform intelligence, marketplace, mobile apps.

### Key Deliverables

| # | Deliverable | Tech |
|---|-------------|------|
| 4.1 | React Native mobile app (iOS + Android) | React Native |
| 4.2 | TV application (dashboards) | React Native TV |
| 4.3 | Vendor/supplier marketplace | Next.js + NestJS |
| 4.4 | Advanced analytics: ML demand forecasting | Python + Julia |
| 4.5 | FinanceAgent: cash flow AI, payment risk | LangGraph |
| 4.6 | SchedulingAgent: AI-optimised resource allocation | LangGraph |
| 4.7 | Mojo inference acceleration layer | Mojo |
| 4.8 | Gleam functional microservices (audit) | Gleam |
| 4.9 | Formal smart contract verification | Certora |
| 4.10 | Multi-tenant white-label offering | Architecture |
| 4.11 | Public API + developer portal | NestJS + Next.js |
| 4.12 | Crystal high-performance scripting services | Crystal |

---

## Sprint Ceremony Structure

Each 2-week sprint follows:

| Day | Ceremony |
|-----|---------|
| Monday Week 1 | Sprint Planning (2 hours) |
| Daily | Standup (15 minutes, async-first) |
| Friday Week 1 | Mid-sprint checkpoint (30 minutes) |
| Thursday Week 2 | Demo preparation |
| Friday Week 2 | Sprint Review + Demo (1 hour) |
| Friday Week 2 | Sprint Retrospective (45 minutes) |
| Friday Week 2 | Backlog Refinement (1 hour) |

---

## Definition of Done

A feature is **Done** when:
- [ ] Code written and peer-reviewed (human-reviewed, not just AI-reviewed)
- [ ] Unit tests written (≥ 80% coverage on new code)
- [ ] Integration tests pass
- [ ] E2E tests pass for user-facing features
- [ ] Security scan clean (no critical/high vulnerabilities)
- [ ] Documentation updated
- [ ] Design system compliance verified
- [ ] Performance budget not exceeded (LCP, API latency)
- [ ] Deployed to staging and smoke-tested
- [ ] Product owner accepted

---

## Risk Register

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Polygon CDK complexity | High | High | Start with testnet; engage Polygon Labs support |
| Elixir team skills gap | Medium | High | Training sprint before Phase 2; consider Phoenix-native devs |
| AI cost overrun | Medium | Medium | Aggressive token routing to Haiku; cost alerts at $50/hr |
| Supabase RLS complexity | Medium | Medium | RLS templates designed in Phase 0 |
| SA payment gateway instability | Low | High | Dual gateway (Peach + Stripe fallback) |
| Data residency compliance | Low | Critical | All production infrastructure in af-south-1 |
