# BEIE Nexus — Engineering Standards & LoC Guidelines
**Document:** ENG-001 | **Version:** 1.0.0 | **Status:** Enforced

---

## 1. Lines of Code (LoC) Guidelines

### 1.1 Philosophy

LoC is a **health signal**, not a productivity metric. The goal is code that is:
- **Readable** — another engineer understands intent in < 30 seconds
- **Testable** — every logic unit can be tested in isolation
- **Reviewable** — a PR can be fully reviewed in < 30 minutes

### 1.2 File Size Limits

| File Type | Soft Limit | Hard Limit | Action on Breach |
|-----------|-----------|-----------|-----------------|
| TypeScript component | 250 LoC | 400 LoC | Split into subcomponents |
| TypeScript service | 300 LoC | 500 LoC | Extract domain logic |
| NestJS controller | 150 LoC | 250 LoC | Split routes |
| Go service file | 400 LoC | 600 LoC | Extract packages |
| Elixir module | 200 LoC | 350 LoC | Split contexts |
| Python agent | 300 LoC | 500 LoC | Split graph nodes |
| Kotlin service | 350 LoC | 550 LoC | Extract classes |
| Rust module | 400 LoC | 650 LoC | Split modules |
| Solidity contract | 300 LoC | 450 LoC | Separate contracts |
| SQL migration | 100 LoC | 200 LoC | Split migrations |
| Test file | Unlimited | — | Tests are exempt |

### 1.3 Function Size Limits

| Language | Max Function LoC | Max Cyclomatic Complexity |
|----------|-----------------|--------------------------|
| TypeScript | 50 | 10 |
| Go | 60 | 12 |
| Python | 50 | 10 |
| Elixir | 30 (functions) | 8 |
| Kotlin | 50 | 10 |
| Rust | 60 | 12 |
| Solidity | 40 | 8 |

### 1.4 PR Size Guidelines

| PR Size | LoC Changed | Review SLA |
|---------|------------|-----------|
| Micro | < 50 | 4 hours |
| Small | 50–200 | 8 hours |
| Medium | 200–500 | 24 hours |
| Large | 500–1000 | 48 hours |
| Epic | > 1000 | Split required |

PRs over 1000 LoC are **rejected** unless they are automated migrations (e.g., schema changes, renaming). All PRs include a summary of what changed and why, plus a self-review checklist.

---

## 2. Monorepo Structure

```
beie-nexus/
├── apps/
│   ├── web-public/          # Next.js — corporate website + storefront
│   ├── web-dashboard/       # Angular — ERP + project management
│   ├── web-client-portal/   # Angular — client-facing portal
│   ├── api-gateway/         # NestJS — API gateway + BFF
│   ├── service-ai/          # Python — AI orchestration
│   ├── service-chat/        # Elixir — real-time communication
│   ├── service-erp/         # Kotlin — ERP core
│   ├── service-realtime/    # Go — notifications, file processing
│   ├── service-blockchain/  # Rust — Polygon CDK bridge
│   ├── service-iot/         # Go — IoT telemetry
│   └── mobile/              # React Native
├── packages/
│   ├── ui/                  # Shared component library
│   ├── types/               # Shared TypeScript types
│   ├── config/              # Shared configs (eslint, tsconfig, etc.)
│   ├── utils/               # Shared utilities
│   └── contracts/           # Solidity smart contracts
├── infrastructure/
│   ├── terraform/           # IaC
│   ├── kubernetes/          # K8s manifests
│   ├── docker/              # Dockerfiles
│   └── scripts/             # Operational scripts
├── docs/                    # All documentation (this folder)
├── tools/                   # Build tools, code generators
└── .github/                 # CI/CD workflows
```

### 2.1 Monorepo Tooling

- **Turborepo** — build orchestration, caching
- **pnpm workspaces** — dependency management
- **Nx** — Angular workspace, affected commands
- **Changesets** — versioning and changelogs

---

## 3. Coding Standards by Language

### 3.1 TypeScript (All TS projects)

```typescript
// tsconfig.json strict settings (mandatory)
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "exactOptionalPropertyTypes": true,
    "noUncheckedIndexedAccess": true
  }
}
```

**Rules:**
- `any` type: **BANNED** — use `unknown` and narrow
- `as` type assertions: require a comment explaining why
- `!` non-null assertions: **BANNED** — use guards or optional chaining
- `enum`: prefer `const` objects with `as const` (tree-shakeable)
- Import order: external → internal packages → relative (enforced by ESLint)
- Named exports only (no default exports except Next.js pages/layouts)

### 3.2 Go

- `gofmt` enforced in CI (formatting is non-negotiable)
- Error handling: always check errors; `_` for errors requires a comment
- Context propagation: every function that calls I/O must accept `context.Context` as first parameter
- Goroutines: must have a defined lifecycle; no goroutine leak tolerance
- Struct tags: all DB/JSON structs must have complete tags

### 3.3 Elixir

- Credo: static analysis enforced at level `:strict`
- Dialyzer: type spec for all public functions mandatory
- All GenServers must have `handle_info` for unexpected messages
- Phoenix Channels: always validate params before broadcasting
- Ecto: all queries must be optimised (no N+1); use `Ecto.Multi` for transactions

### 3.4 Python (AI Services)

- Type hints: mandatory on all function signatures (enforced by mypy strict)
- Pydantic: all LLM inputs and outputs must be Pydantic models
- Async: all I/O operations must be async
- Exception handling: never `except Exception` without logging and re-raising
- LangGraph state: must extend `TypedDict`, all fields typed

### 3.5 Kotlin

- Coroutines: all async operations use `suspend` functions
- Null safety: leverage Kotlin's type system; `!!` operator requires justification comment
- Data classes: use for all domain models
- Sealed classes: use for all result types (`Result<T, E>`)
- Spring annotations: minimal; prefer constructor injection

### 3.6 Rust

- `clippy` at `deny(warnings)` level in CI
- `unwrap()` and `expect()` banned in library code; allowed in tests with message
- All public APIs must have documentation comments
- Error types: use `thiserror` for library errors, `anyhow` for application errors
- Async: use `tokio` runtime; all async code must be cancellation-safe

### 3.7 Solidity

- Solidity version: pinned exact (`^0.8.20` minimum)
- All functions must have NatSpec documentation
- ReentrancyGuard: mandatory on all external functions that transfer value
- Events: emitted for every state change
- Access control: OpenZeppelin `AccessControl` or `Ownable`
- No `tx.origin` for authentication
- Integer overflow: use Solidity 0.8+ built-in checks; document any `unchecked` blocks

---

## 4. Git & Branch Strategy

### 4.1 Branch Naming Convention

```
[type]/[ticket-id]-[short-description]

Types:
  feat/     New feature
  fix/      Bug fix
  chore/    Maintenance, dependencies
  docs/     Documentation only
  refactor/ Code restructure (no behaviour change)
  perf/     Performance improvement
  security/ Security fix (fast-track review)
  ai/       AI-generated code (requires human review tag)

Examples:
  feat/NX-142-project-gantt-chart
  fix/NX-201-cart-quantity-overflow
  security/NX-299-jwt-expiry-fix
  ai/NX-310-estimating-agent-v2
```

### 4.2 Commit Message Convention (Conventional Commits)

```
<type>(<scope>): <subject>

<body> (optional, wraps at 72 chars)

<footer> (optional: BREAKING CHANGE, Closes #ticket)

Types: feat, fix, docs, style, refactor, perf, test, chore, security
Scopes: web-public, dashboard, client-portal, api, ai, chat, erp, blockchain, iot

Example:
feat(api): add bulk product import endpoint

Implements CSV-based bulk product upload for e-commerce catalogue.
Supports up to 10,000 products per batch with async processing.
Products are queued via Kafka for background indexing.

Closes #NX-142
```

### 4.3 Branch Protection Rules

| Branch | Protection |
|--------|-----------|
| `main` | Requires 2 reviews, all CI passing, no direct push |
| `staging` | Requires 1 review, all CI passing |
| `develop` | Requires 1 review, lint + unit tests passing |
| `feat/*` | No restrictions (developer freedom) |

---

## 5. Testing Standards

### 5.1 Coverage Requirements

| Layer | Minimum Coverage | Target |
|-------|-----------------|--------|
| Domain logic (services) | 85% | 95% |
| API controllers | 75% | 90% |
| UI components | 70% | 85% |
| Smart contracts | 100% | 100% |
| AI agents | 60% | 80% |

### 5.2 Test Pyramid

```
         ┌─────────────────┐
         │  E2E Tests      │  ~5% of tests  (Playwright)
         │  (slow, broad)  │
        ─┴─────────────────┴─
       ┌──────────────────────┐
       │  Integration Tests   │  ~25% of tests
       │  (API, DB, services) │
      ─┴──────────────────────┴─
    ┌─────────────────────────────┐
    │  Unit Tests                 │  ~70% of tests
    │  (fast, isolated, abundant) │
    └─────────────────────────────┘
```

### 5.3 Testing Tools by Layer

| Layer | Tool |
|-------|------|
| TypeScript unit | Vitest |
| Angular component | Angular Testing Library + Cypress Component |
| Go unit | `testing` package + testify |
| Elixir unit | ExUnit |
| Python unit | pytest + pytest-asyncio |
| Kotlin unit | JUnit 5 + MockK |
| Rust unit | built-in `#[test]` + `tokio::test` |
| Solidity | Hardhat + Foundry |
| API integration | Supertest (NestJS) |
| E2E (web) | Playwright |
| Load testing | k6 |
| Security scanning | Snyk + OWASP ZAP |

---

## 6. Security Standards

### 6.1 Mandatory Security Controls

- **SAST**: SonarQube + Snyk on every PR
- **Secret scanning**: Gitleaks pre-commit hook + GitHub secret scanning
- **Dependency scanning**: Dependabot + Snyk on all repos, weekly
- **Container scanning**: Trivy in CI, no HIGH/CRITICAL vulnerabilities in production images
- **DAST**: OWASP ZAP on staging, weekly scheduled scan
- **Penetration testing**: External pentest at Phase 1 completion and annually

### 6.2 Input Validation Rules

- All API inputs validated with class-validator (NestJS) or Zod (TypeScript utilities)
- SQL: parameterised queries only — string interpolation into SQL is a firing offence
- File uploads: validate MIME type, extension, size server-side (client-side is UX only)
- Max payload: 10MB default, 100MB for file upload endpoints
- Rate limiting: 100 req/min per IP (unauthenticated), 1000 req/min per authenticated user

### 6.3 Cryptography Standards

- Passwords: bcrypt (cost factor 12) via Supabase Auth
- JWT: RS256 (asymmetric), 15-minute expiry
- API keys: 256-bit random, stored as SHA-256 hash only
- Data encryption at rest: AES-256-GCM via Vault
- TLS: 1.3 minimum, TLS 1.0/1.1 disabled
- Blockchain keys: HSM-backed (Phase 2+), Vault-backed (Phase 1)

---

## 7. API Design Standards

### 7.1 REST Conventions

```
Resources: plural nouns       /api/v1/projects
Hierarchy: /parent/id/child   /api/v1/projects/123/tasks
Methods:
  GET    → read (idempotent)
  POST   → create
  PUT    → full replace
  PATCH  → partial update
  DELETE → remove

Status codes:
  200 OK             → successful GET, PUT, PATCH
  201 Created        → successful POST (include Location header)
  204 No Content     → successful DELETE
  400 Bad Request    → validation error (include error details)
  401 Unauthorized   → not authenticated
  403 Forbidden      → authenticated but not authorised
  404 Not Found
  409 Conflict       → duplicate resource
  422 Unprocessable  → semantic validation error
  429 Too Many Req   → rate limited (include Retry-After header)
  500 Internal Error → never expose stack traces
```

### 7.2 Response Envelope

```typescript
// Success
{
  "data": <payload>,
  "meta": {
    "page": 1,
    "perPage": 25,
    "total": 150,
    "requestId": "uuid-v7"
  }
}

// Error
{
  "error": {
    "code": "VALIDATION_ERROR",       // Machine-readable
    "message": "Validation failed",    // Human-readable
    "details": [                       // Optional array
      { "field": "email", "message": "Invalid email format" }
    ],
    "requestId": "uuid-v7",
    "timestamp": "ISO 8601"
  }
}
```

### 7.3 Versioning

- URL versioning: `/api/v1/`, `/api/v2/`
- Support minimum 2 major versions simultaneously
- Deprecation notice: 6 months minimum, communicated via `Deprecation` and `Sunset` headers
- Breaking changes require a new major version; never break existing clients

---

## 8. Documentation Standards

### 8.1 Required Documentation

| Artifact | Tool | When Required |
|----------|------|--------------|
| API reference | OpenAPI 3.1 (auto-generated) | All endpoints |
| Architecture Decision Record | ADR template | Any significant decision |
| Runbook | Markdown | All production services |
| Component Storybook | Storybook | All shared UI components |
| Database schema | Prisma schema + auto-generated ERD | All schemas |
| Smart contract | NatSpec | All public functions |
| Agent specification | Agent spec template | All AI agents |

### 8.2 Architecture Decision Record (ADR) Template

```markdown
# ADR-[number]: [Title]

**Date:** YYYY-MM-DD  
**Status:** Proposed | Accepted | Deprecated | Superseded by ADR-XXX  
**Deciders:** [Names]

## Context
What is the problem or opportunity?

## Decision
What did we decide?

## Rationale
Why did we make this decision?

## Consequences
What are the positive and negative consequences?

## Alternatives Considered
What else did we evaluate and why did we reject it?
```

---

*Engineering standards are enforced by automated tooling where possible. Human judgment governs where automation falls short.*
