# BEIE Nexus — Master Documentation Index
**The Singularity Orchestration Platform for Electrical & Instrumentation Engineering**  
**Version:** 1.0.0 | **Date:** April 2026 | **Owner:** Bellwether E&I Engineering (Pty) Ltd

---

## Document Registry

| # | Document | ID | Description |
|---|----------|----|-------------|
| 1 | [System Architecture](./01_SYSTEM_ARCHITECTURE.md) | ARCH-001 | Master architecture, tech stack, infrastructure topology |
| 2 | [AI Rules & Agentic Guidelines](./02_AI_RULES_AND_AGENTIC_GUIDELINES.md) | AI-001 | All AI agent rules, HITL gates, LLM standards |
| 3 | [Development Roadmap](./03_DEVELOPMENT_ROADMAP.md) | ROAD-001 | 18-month phased roadmap, sprint structure |
| 4 | [UI/UX Design System](./04_UI_UX_DESIGN_SYSTEM.md) | UI-001 | Design tokens, device guidelines, component standards |
| 5 | [Engineering Standards & LoC](./05_ENGINEERING_STANDARDS_LOC.md) | ENG-001 | Coding standards, PR rules, test coverage, security |
| 6 | [Domain Specifications](./06_DOMAIN_SPECIFICATIONS.md) | DOM-001 | E-commerce, project management, ERP, chat, blockchain |
| 7 | [Security Architecture](./07_SECURITY_ARCHITECTURE.md) | SEC-001 | Threat model, auth, encryption, incident response |
| 8 | [State & Project Management](./08_STATE_AND_PROJECT_MANAGEMENT.md) | STATE-001 | NgRx/Zustand patterns, PM methodology, reporting |

---

## System at a Glance

```
BEIE NEXUS — SYSTEM OVERVIEW

┌─────────────────────────────────────────────────────────────────────┐
│                    BEIE NEXUS PLATFORM                               │
│                                                                      │
│  PUBLIC FACE              OPERATIONAL CORE          INTELLIGENCE     │
│  ┌─────────────┐          ┌─────────────┐          ┌─────────────┐  │
│  │ Next.js     │          │ Angular     │          │ Python AI   │  │
│  │ Corporate   │          │ Dashboard   │          │ LangGraph   │  │
│  │ Website     │          │ ERP / PM    │          │ CrewAI      │  │
│  │ E-Commerce  │          │ Client      │          │ Claude API  │  │
│  └─────────────┘          │ Portal      │          └─────────────┘  │
│                           └─────────────┘                           │
│                                                                      │
│  COMMUNICATION            INFRASTRUCTURE           AUDIT LAYER      │
│  ┌─────────────┐          ┌─────────────┐          ┌─────────────┐  │
│  │ Elixir      │          │ AWS af-s-1  │          │ Polygon CDK │  │
│  │ Nexus Chat  │          │ Coolify     │          │ Rust Bridge │  │
│  │ (Slack-like)│          │ Cloudflare  │          │ Solidity    │  │
│  └─────────────┘          │ Kubernetes  │          │ IPFS        │  │
│                           └─────────────┘          └─────────────┘  │
│                                                                      │
│  ERP CORE                 DATA LAYER               MOBILE           │
│  ┌─────────────┐          ┌─────────────┐          ┌─────────────┐  │
│  │ Kotlin      │          │ Supabase    │          │ React Native│  │
│  │ Spring Boot │          │ MongoDB     │          │ iOS + Android│ │
│  │ Finance     │          │ Upstash     │          │ TV App      │  │
│  │ HR/Payroll  │          │ ClickHouse  │          └─────────────┘  │
│  └─────────────┘          └─────────────┘                           │
└─────────────────────────────────────────────────────────────────────┘

           "AI proposes. Humans approve. Blockchain records."
```

---

## Development Phases Summary

| Phase | Duration | Key Deliverable | Status |
|-------|----------|----------------|--------|
| Phase 0 — Foundation | Weeks 1–4 | Infrastructure, CI/CD, DevOps | 🔵 Planning |
| Phase 1 — Core Platform | Weeks 5–20 | Website, E-Commerce, PM, Client Portal | 🔵 Planning |
| Phase 2 — Communication & ERP | Weeks 21–36 | Nexus Chat, ERP, First AI Agents | 🔵 Planning |
| Phase 3 — Blockchain & IoT | Weeks 37–52 | Polygon CDK, Advanced AI, IoT | 🔵 Planning |
| Phase 4 — Intelligence & Scale | Weeks 53–72 | Mobile, ML, Marketplace | 🔵 Planning |

---

## Key Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Frontend (public) | Next.js 15 | SSR, SEO, e-commerce patterns |
| Frontend (dashboard) | Angular 19 | Enterprise forms, strong typing, RBAC |
| API layer | NestJS | TypeScript consistency, decorators, DI |
| Real-time chat | Elixir/Phoenix | Purpose-built for concurrent real-time |
| ERP | Kotlin/Spring Boot | JVM reliability, SA tax library ecosystem |
| AI orchestration | Python + LangGraph | The only viable ecosystem for this use case |
| Blockchain | Polygon CDK | Permissioned L2, low gas, enterprise-grade |
| Primary DB | Supabase | PostgreSQL + auth + realtime + storage in one |
| Catalogue DB | MongoDB Atlas | Flexible schema for diverse product specs |
| Deployment (prod) | AWS af-south-1 | Data sovereignty, SA latency |
| Deployment (dev) | Coolify | Cost-effective self-hosted |

---

## Glossary

| Term | Definition |
|------|-----------|
| **Nexus** | The BEIE platform product name |
| **Nexus Chat** | BEIE's Slack-like communication layer |
| **Nexus Chain** | BEIE's Polygon CDK blockchain audit layer |
| **HITL** | Human-in-the-Loop — mandatory human approval gate |
| **BAS/BMS** | Building Automation System / Building Management System |
| **CoC** | Certificate of Compliance (electrical) |
| **SLA** | Service Level Agreement |
| **SANS** | South African National Standard |
| **RLS** | Row-Level Security (Supabase/PostgreSQL feature) |
| **RBAC** | Role-Based Access Control |
| **ABAC** | Attribute-Based Access Control |
| **POPIA** | Protection of Personal Information Act (SA equivalent of GDPR) |
| **BCEA** | Basic Conditions of Employment Act |
| **ECA(SA)** | Electrical Contractors Association of South Africa |
| **ECSA** | Engineering Council of South Africa |
| **NERSA** | National Energy Regulator of South Africa |
| **IPPPP** | Independent Power Producer Procurement Programme |
| **VFD** | Variable Frequency Drive |
| **PLC** | Programmable Logic Controller |
| **SCADA** | Supervisory Control and Data Acquisition |
| **IPFS** | InterPlanetary File System |
| **CDK** | Chain Development Kit (Polygon) |
| **ADR** | Architecture Decision Record |
| **LoC** | Lines of Code |
| **SAST** | Static Application Security Testing |
| **DAST** | Dynamic Application Security Testing |
| **IaC** | Infrastructure as Code |
| **mTLS** | Mutual TLS |

---

*This documentation suite is maintained in the `docs/` folder of the BEIE Nexus monorepo and version-controlled alongside the codebase. All changes require a PR with human review.*

---

**BEIE Nexus** | Built for the built environment | KwaZulu-Natal, South Africa  
*© 2026 Bellwether Electrical & Instrumentation Engineering (Pty) Ltd*
