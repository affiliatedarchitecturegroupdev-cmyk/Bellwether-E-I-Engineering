# BEIE Nexus — Database Schema & Data Governance
**Document:** DB-001 | **Version:** 1.0.0

---

## 1. Supabase (PostgreSQL) — Core Schema

### 1.1 Schema Organisation

```sql
-- Schemas separate domains (each has its own RLS policies)
CREATE SCHEMA IF NOT EXISTS iam;        -- Identity & access management
CREATE SCHEMA IF NOT EXISTS projects;   -- Project management
CREATE SCHEMA IF NOT EXISTS ecommerce;  -- E-commerce (orders, not catalogue)
CREATE SCHEMA IF NOT EXISTS erp;        -- ERP (finance, HR, assets)
CREATE SCHEMA IF NOT EXISTS comms;      -- Notifications, chat metadata
CREATE SCHEMA IF NOT EXISTS ai;         -- AI tasks, agent logs
CREATE SCHEMA IF NOT EXISTS blockchain; -- On-chain references
CREATE SCHEMA IF NOT EXISTS audit;      -- Immutable audit log
```

### 1.2 IAM Schema

```sql
-- Tenants (multi-tenancy root)
CREATE TABLE iam.tenants (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT NOT NULL,
    slug            TEXT NOT NULL UNIQUE,
    plan            TEXT NOT NULL DEFAULT 'professional',
    status          TEXT NOT NULL DEFAULT 'active',
    settings        JSONB NOT NULL DEFAULT '{}',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Profiles (extends Supabase auth.users)
CREATE TABLE iam.profiles (
    id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    tenant_id       UUID NOT NULL REFERENCES iam.tenants(id),
    role            TEXT NOT NULL DEFAULT 'engineer',
    first_name      TEXT NOT NULL,
    last_name       TEXT NOT NULL,
    display_name    TEXT GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
    avatar_url      TEXT,
    phone           TEXT,        -- Encrypted at application layer
    department      TEXT,
    job_title       TEXT,
    status          TEXT NOT NULL DEFAULT 'active',
    mfa_enabled     BOOLEAN NOT NULL DEFAULT FALSE,
    last_active_at  TIMESTAMPTZ,
    preferences     JSONB NOT NULL DEFAULT '{}',  -- Theme, notifications, etc.
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- API Keys (for programmatic/IoT access)
CREATE TABLE iam.api_keys (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES iam.tenants(id),
    user_id         UUID REFERENCES iam.profiles(id),
    name            TEXT NOT NULL,
    key_hash        TEXT NOT NULL UNIQUE,  -- SHA-256, never store plain text
    scopes          TEXT[] NOT NULL DEFAULT '{}',
    last_used_at    TIMESTAMPTZ,
    expires_at      TIMESTAMPTZ,
    revoked_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Clients (BEIE's customers)
CREATE TABLE iam.clients (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES iam.tenants(id),
    company_name    TEXT NOT NULL,
    trading_name    TEXT,
    registration_no TEXT,
    vat_number      TEXT,        -- Encrypted
    sector          TEXT NOT NULL,  -- commercial | industrial | residential
    tier            TEXT NOT NULL DEFAULT 'standard',  -- standard | preferred | key
    credit_limit    NUMERIC(15,2),
    payment_terms   INTEGER NOT NULL DEFAULT 30,  -- Days
    billing_address JSONB NOT NULL DEFAULT '{}',
    contacts        JSONB NOT NULL DEFAULT '[]',  -- Array of contact persons
    status          TEXT NOT NULL DEFAULT 'active',
    notes           TEXT,
    created_by      UUID REFERENCES iam.profiles(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 1.3 Projects Schema

```sql
-- Projects
CREATE TABLE projects.projects (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES iam.tenants(id),
    code                TEXT NOT NULL,  -- BEIE-2026-XXXX
    name                TEXT NOT NULL,
    description         TEXT,
    client_id           UUID NOT NULL REFERENCES iam.clients(id),
    sector              TEXT NOT NULL,  -- commercial | industrial | residential | renewable
    project_type        TEXT NOT NULL,
    status              TEXT NOT NULL DEFAULT 'enquiry',
    priority            TEXT NOT NULL DEFAULT 'medium',
    
    -- Team
    project_manager_id  UUID REFERENCES iam.profiles(id),
    engineer_id         UUID REFERENCES iam.profiles(id),
    
    -- Site
    site_address        JSONB NOT NULL DEFAULT '{}',
    site_coordinates    POINT,           -- PostGIS point for map view
    erf_number          TEXT,
    
    -- Dates
    enquiry_date        DATE,
    contract_signed_at  TIMESTAMPTZ,
    start_date          DATE,
    target_completion   DATE,
    actual_completion   DATE,
    defects_expiry      DATE,
    
    -- Financials
    contract_value      NUMERIC(15,2),
    contract_currency   CHAR(3) NOT NULL DEFAULT 'ZAR',
    retention_pct       NUMERIC(5,2) NOT NULL DEFAULT 5.00,
    
    -- Blockchain
    blockchain_refs     TEXT[] NOT NULL DEFAULT '{}',
    
    -- Metadata
    tags                TEXT[] NOT NULL DEFAULT '{}',
    custom_fields       JSONB NOT NULL DEFAULT '{}',
    created_by          UUID REFERENCES iam.profiles(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(tenant_id, code),
    CHECK (contract_value >= 0)
);

-- Project Phases
CREATE TABLE projects.phases (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id      UUID NOT NULL REFERENCES projects.projects(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    description     TEXT,
    sequence        INTEGER NOT NULL,
    status          TEXT NOT NULL DEFAULT 'not_started',
    start_date      DATE,
    end_date        DATE,
    completion_date DATE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(project_id, sequence)
);

-- Tasks
CREATE TABLE projects.tasks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES iam.tenants(id),
    project_id      UUID NOT NULL REFERENCES projects.projects(id) ON DELETE CASCADE,
    phase_id        UUID REFERENCES projects.phases(id),
    parent_task_id  UUID REFERENCES projects.tasks(id),  -- Subtasks
    
    title           TEXT NOT NULL,
    description     TEXT,
    status          TEXT NOT NULL DEFAULT 'todo',
    priority        TEXT NOT NULL DEFAULT 'medium',
    
    assignee_id     UUID REFERENCES iam.profiles(id),
    reporter_id     UUID REFERENCES iam.profiles(id),
    
    estimated_hours NUMERIC(6,2),
    actual_hours    NUMERIC(6,2) DEFAULT 0,
    due_date        DATE,
    completed_at    TIMESTAMPTZ,
    
    tags            TEXT[] NOT NULL DEFAULT '{}',
    custom_fields   JSONB NOT NULL DEFAULT '{}',
    
    created_by      UUID REFERENCES iam.profiles(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Task Dependencies (many-to-many)
CREATE TABLE projects.task_dependencies (
    task_id         UUID NOT NULL REFERENCES projects.tasks(id) ON DELETE CASCADE,
    depends_on_id   UUID NOT NULL REFERENCES projects.tasks(id) ON DELETE CASCADE,
    dependency_type TEXT NOT NULL DEFAULT 'finish_to_start',
    PRIMARY KEY (task_id, depends_on_id),
    CHECK (task_id <> depends_on_id)
);

-- Milestones
CREATE TABLE projects.milestones (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id          UUID NOT NULL REFERENCES projects.projects(id) ON DELETE CASCADE,
    phase_id            UUID REFERENCES projects.phases(id),
    
    name                TEXT NOT NULL,
    description         TEXT,
    status              TEXT NOT NULL DEFAULT 'upcoming',
    
    due_date            DATE NOT NULL,
    completion_date     DATE,
    
    invoice_trigger     BOOLEAN NOT NULL DEFAULT FALSE,
    invoice_pct         NUMERIC(5,2),
    invoice_id          UUID,  -- Set when invoice created
    
    approved_by         UUID REFERENCES iam.profiles(id),
    approved_at         TIMESTAMPTZ,
    
    blockchain_ref      TEXT,  -- Polygon CDK tx hash
    ipfs_cid            TEXT,
    
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Project Documents
CREATE TABLE projects.documents (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id      UUID NOT NULL REFERENCES projects.projects(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    type            TEXT NOT NULL,  -- drawing | spec | report | cert | correspondence
    revision        TEXT NOT NULL DEFAULT 'A',
    status          TEXT NOT NULL DEFAULT 'current',
    file_path       TEXT NOT NULL,  -- Supabase Storage path
    file_size       BIGINT,
    mime_type       TEXT,
    description     TEXT,
    blockchain_ref  TEXT,           -- For compliance documents
    uploaded_by     UUID REFERENCES iam.profiles(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Project Activity Log (append-only)
CREATE TABLE projects.activity_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id      UUID NOT NULL REFERENCES projects.projects(id),
    tenant_id       UUID NOT NULL,
    actor_id        UUID NOT NULL REFERENCES iam.profiles(id),
    actor_type      TEXT NOT NULL DEFAULT 'user',  -- user | agent | system
    event_type      TEXT NOT NULL,  -- task.status_changed, milestone.completed, etc.
    entity_type     TEXT NOT NULL,
    entity_id       UUID NOT NULL,
    old_value       JSONB,
    new_value       JSONB,
    metadata        JSONB NOT NULL DEFAULT '{}',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
) PARTITION BY RANGE (created_at);  -- Time-based partitioning for scale

-- Create partitions quarterly
CREATE TABLE projects.activity_log_2026_q2 PARTITION OF projects.activity_log
    FOR VALUES FROM ('2026-04-01') TO ('2026-07-01');
CREATE TABLE projects.activity_log_2026_q3 PARTITION OF projects.activity_log
    FOR VALUES FROM ('2026-07-01') TO ('2026-10-01');
```

### 1.4 ERP Schema (Finance)

```sql
-- Invoices
CREATE TABLE erp.invoices (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES iam.tenants(id),
    invoice_number      TEXT NOT NULL,   -- BEIE-INV-2026-XXXX
    client_id           UUID NOT NULL REFERENCES iam.clients(id),
    project_id          UUID REFERENCES projects.projects(id),
    milestone_id        UUID REFERENCES projects.milestones(id),
    
    status              TEXT NOT NULL DEFAULT 'draft',
    type                TEXT NOT NULL DEFAULT 'tax_invoice',  -- tax_invoice | credit_note | proforma
    
    issue_date          DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date            DATE NOT NULL,
    payment_terms       INTEGER NOT NULL DEFAULT 30,
    
    -- Line items stored as JSONB for flexibility
    line_items          JSONB NOT NULL DEFAULT '[]',
    
    -- Totals (denormalised for performance)
    subtotal_excl_vat   NUMERIC(15,2) NOT NULL,
    vat_amount          NUMERIC(15,2) NOT NULL,
    total_incl_vat      NUMERIC(15,2) NOT NULL,
    retention_held      NUMERIC(15,2) NOT NULL DEFAULT 0,
    
    currency            CHAR(3) NOT NULL DEFAULT 'ZAR',
    
    -- Payment tracking
    amount_paid         NUMERIC(15,2) NOT NULL DEFAULT 0,
    balance_due         NUMERIC(15,2) GENERATED ALWAYS AS 
                            (total_incl_vat - amount_paid) STORED,
    paid_at             TIMESTAMPTZ,
    
    -- References
    po_number           TEXT,     -- Client's purchase order number
    notes               TEXT,
    pdf_path            TEXT,     -- Supabase Storage
    blockchain_ref      TEXT,     -- Anchored on issue
    
    created_by          UUID REFERENCES iam.profiles(id),
    approved_by         UUID REFERENCES iam.profiles(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(tenant_id, invoice_number)
);

-- Payments
CREATE TABLE erp.payments (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES iam.tenants(id),
    invoice_id          UUID NOT NULL REFERENCES erp.invoices(id),
    
    amount              NUMERIC(15,2) NOT NULL,
    currency            CHAR(3) NOT NULL DEFAULT 'ZAR',
    payment_date        DATE NOT NULL,
    method              TEXT NOT NULL,  -- eft | card | cash | other
    reference           TEXT,           -- Bank reference / receipt number
    notes               TEXT,
    
    recorded_by         UUID REFERENCES iam.profiles(id),
    blockchain_ref      TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CHECK (amount > 0)
);

-- Journal Entries (double-entry bookkeeping)
CREATE TABLE erp.journal_entries (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES iam.tenants(id),
    journal_number  TEXT NOT NULL,
    description     TEXT NOT NULL,
    reference       TEXT,
    entry_date      DATE NOT NULL,
    period          TEXT NOT NULL,  -- YYYY-MM
    status          TEXT NOT NULL DEFAULT 'posted',  -- draft | posted | reversed
    source          TEXT NOT NULL,  -- invoice | payment | payroll | manual
    source_id       UUID,
    created_by      UUID REFERENCES iam.profiles(id),
    approved_by     UUID REFERENCES iam.profiles(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Journal Lines
CREATE TABLE erp.journal_lines (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    journal_id      UUID NOT NULL REFERENCES erp.journal_entries(id),
    account_code    TEXT NOT NULL,
    description     TEXT,
    debit           NUMERIC(15,2) NOT NULL DEFAULT 0,
    credit          NUMERIC(15,2) NOT NULL DEFAULT 0,
    
    CHECK (debit >= 0 AND credit >= 0),
    CHECK (debit = 0 OR credit = 0)  -- Can't be both debit and credit
);
```

### 1.5 AI Schema

```sql
-- AI Tasks (async agent invocations)
CREATE TABLE ai.tasks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES iam.tenants(id),
    requester_id    UUID REFERENCES iam.profiles(id),
    
    agent           TEXT NOT NULL,  -- EstimatingAgent | ComplianceAgent | etc.
    task_type       TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'queued',  -- queued | running | awaiting_human | completed | failed
    
    input_payload   JSONB NOT NULL,
    output_payload  JSONB,
    
    confidence      NUMERIC(4,3),  -- 0.000 - 1.000
    requires_human  BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- HITL
    reviewer_id     UUID REFERENCES iam.profiles(id),
    reviewed_at     TIMESTAMPTZ,
    human_decision  TEXT,  -- approved | rejected | modified
    human_feedback  TEXT,
    
    -- Performance
    model_used      TEXT,
    tokens_input    INTEGER,
    tokens_output   INTEGER,
    cost_usd        NUMERIC(10,6),
    duration_ms     INTEGER,
    
    -- Audit
    blockchain_ref  TEXT,
    error_message   TEXT,
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at    TIMESTAMPTZ
);

-- Agent Audit Log (immutable, append-only)
CREATE TABLE ai.audit_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id         UUID REFERENCES ai.tasks(id),
    tenant_id       UUID NOT NULL,
    agent           TEXT NOT NULL,
    action          TEXT NOT NULL,
    input_hash      CHAR(64),   -- SHA-256
    output_hash     CHAR(64),
    metadata        JSONB NOT NULL DEFAULT '{}',
    blockchain_ref  TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
    -- No updates or deletes allowed (enforced by trigger)
);

-- Prevent any updates or deletes on audit log
CREATE OR REPLACE FUNCTION ai.prevent_audit_log_mutation()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Audit log is immutable. No updates or deletes permitted.';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_log_immutable
    BEFORE UPDATE OR DELETE ON ai.audit_log
    FOR EACH ROW EXECUTE FUNCTION ai.prevent_audit_log_mutation();
```

### 1.6 Blockchain Schema

```sql
-- On-chain record references
CREATE TABLE blockchain.anchors (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    event_type      TEXT NOT NULL,
    entity_type     TEXT NOT NULL,
    entity_id       UUID NOT NULL,
    
    -- Polygon CDK
    tx_hash         TEXT NOT NULL UNIQUE,
    block_number    BIGINT,
    contract_address TEXT NOT NULL,
    network         TEXT NOT NULL DEFAULT 'beie-polygon-cdn',
    
    -- IPFS
    ipfs_cid        TEXT,
    ipfs_url        TEXT GENERATED ALWAYS AS 
                        ('https://ipfs.beie.co.za/ipfs/' || ipfs_cid) STORED,
    
    -- Payload
    payload_hash    CHAR(64) NOT NULL,  -- SHA-256 of anchored data
    
    -- Public verification URL
    verify_url      TEXT GENERATED ALWAYS AS 
                        ('https://verify.beie.co.za/' || tx_hash) STORED,
    
    confirmed_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## 2. Database Indexes (Performance Critical)

```sql
-- Projects
CREATE INDEX idx_projects_tenant ON projects.projects(tenant_id);
CREATE INDEX idx_projects_client ON projects.projects(client_id);
CREATE INDEX idx_projects_status ON projects.projects(status);
CREATE INDEX idx_projects_pm ON projects.projects(project_manager_id);
CREATE INDEX idx_projects_code ON projects.projects(code);
CREATE INDEX idx_projects_created ON projects.projects(created_at DESC);
CREATE INDEX idx_projects_site ON projects.projects USING GIST(site_coordinates);

-- Tasks
CREATE INDEX idx_tasks_project ON projects.tasks(project_id);
CREATE INDEX idx_tasks_assignee ON projects.tasks(assignee_id);
CREATE INDEX idx_tasks_status ON projects.tasks(status);
CREATE INDEX idx_tasks_due ON projects.tasks(due_date) WHERE status != 'done';
CREATE INDEX idx_tasks_tenant ON projects.tasks(tenant_id);

-- Invoices
CREATE INDEX idx_invoices_tenant ON erp.invoices(tenant_id);
CREATE INDEX idx_invoices_client ON erp.invoices(client_id);
CREATE INDEX idx_invoices_project ON erp.invoices(project_id);
CREATE INDEX idx_invoices_status ON erp.invoices(status);
CREATE INDEX idx_invoices_due ON erp.invoices(due_date) WHERE status != 'paid';

-- AI Tasks
CREATE INDEX idx_ai_tasks_tenant ON ai.tasks(tenant_id);
CREATE INDEX idx_ai_tasks_status ON ai.tasks(status);
CREATE INDEX idx_ai_tasks_requires_human ON ai.tasks(requires_human) WHERE requires_human = TRUE;
CREATE INDEX idx_ai_tasks_agent ON ai.tasks(agent);
```

---

## 3. Migration Strategy

### 3.1 Migration Rules

- Every schema change is a numbered migration: `V{number}__{description}.sql`
- Migrations are **forward-only** in production (no down migrations)
- Every migration runs in a transaction (except index creation which is non-blocking)
- Migrations are tested in staging before production
- Zero-downtime migration patterns:
  1. Add column nullable (non-breaking)
  2. Backfill data
  3. Add NOT NULL constraint
  4. Deploy new code
  5. Drop old column (separate later migration)

### 3.2 Migration Tooling

- **Flyway** for PostgreSQL migrations (Supabase)
- **Liquibase** for ERP (Kotlin/Spring Boot)
- Migration files live in `packages/database/migrations/`
- CI runs `flyway validate` on every PR

---

## 4. MongoDB Atlas — Product Catalogue

### 4.1 Collection Strategy

```
beie_catalogue database
├── products              # Core product documents
├── categories            # Category tree
├── brands                # Brand profiles
├── product_reviews       # Future: customer reviews
└── search_synonyms       # "MCB" → "miniature circuit breaker"
```

### 4.2 Indexes (MongoDB)

```javascript
// products collection
db.products.createIndex({ sku: 1 }, { unique: true });
db.products.createIndex({ "category.l1": 1, "category.l2": 1 });
db.products.createIndex({ brand: 1 });
db.products.createIndex({ status: 1 });
db.products.createIndex({ "pricing.listPrice": 1 });
db.products.createIndex({ tags: 1 });
db.products.createIndex({ 
    name: "text", 
    "description.short": "text",
    searchIndex: "text" 
}, { 
    weights: { name: 10, "description.short": 5, searchIndex: 1 },
    name: "product_text_search"
});

// Atlas Vector Search index (for semantic search)
db.products.createSearchIndex({
    name: "product_vector_search",
    type: "vectorSearch",
    definition: {
        fields: [{
            type: "vector",
            path: "embedding",
            numDimensions: 1536,  // text-embedding-3-small
            similarity: "cosine"
        }]
    }
});
```

---

## 5. Data Governance

### 5.1 Data Classification

| Classification | Examples | Access | Encryption |
|---------------|---------|--------|-----------|
| **Public** | Product catalogue, public website content | Anyone | In transit |
| **Internal** | Project names, client names, invoice totals | Staff | In transit + at rest |
| **Confidential** | Financial details, salary data, margins | Role-restricted | Application-level |
| **Restricted** | ID numbers, bank accounts, tax numbers | Need-to-know + audit | Application-level |
| **Secret** | Blockchain private keys, JWT signing keys | Systems only (Vault) | HSM/Vault |

### 5.2 Data Lineage

Every record must be traceable:
- `created_by` — who created it
- `created_at` — when
- `updated_at` — last modified (triggers via database trigger)
- `tenant_id` — which organisation owns it
- For financial and compliance records: full event sourcing via `activity_log`

### 5.3 Backup Strategy

| Database | Backup Frequency | Retention | Location | Test Restore |
|----------|-----------------|-----------|---------|--------------|
| Supabase (PostgreSQL) | Continuous WAL + daily snapshot | 30 days (daily), 1 year (monthly) | AWS S3 af-south-1 | Monthly |
| MongoDB Atlas | Continuous oplog + daily snapshot | 30 days | Atlas managed | Monthly |
| ClickHouse | Daily snapshot | 90 days | AWS S3 | Quarterly |
| Redis | RDB snapshot every 6h | 7 days | AWS S3 | Quarterly |

### 5.4 Automated `updated_at` Trigger

```sql
-- Applied to all tables with updated_at column
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to each table:
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON projects.projects
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
```

---

*Database changes must go through the migration process. Direct schema alterations in production are prohibited.*
