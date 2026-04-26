# BEIE Nexus — Security Architecture
**Document:** SEC-001 | **Version:** 1.0.0 | **Classification:** CONFIDENTIAL  
**Security Contact:** security@beie.co.za

---

## 1. Security Philosophy

**Defence in Depth.** Every layer assumes the layer above it has been compromised. No single control is relied upon. Security is designed in from the foundation — it cannot be patched in after the fact.

**Zero Trust.** No implicit trust anywhere in the system. Every request is authenticated, authorised, and logged, whether it originates from outside the network or from within a microservice.

**Least Privilege.** Every user, service account, and system component has only the minimum permissions required to perform its function. Permissions are granted explicitly and reviewed quarterly.

---

## 2. Threat Model

### 2.1 Assets to Protect

| Asset | Classification | Risk if Compromised |
|-------|---------------|---------------------|
| Client financial data | CRITICAL | Regulatory violation, client trust |
| Compliance certificates (CoC) | CRITICAL | Legal liability, fraud |
| Employee PII & payroll | CRITICAL | POPIA violation, identity theft |
| Project commercial data | HIGH | Competitive disadvantage |
| Product pricing & margins | HIGH | Commercial harm |
| Blockchain private keys | CRITICAL | Irreversible asset loss |
| AI agent system prompts | MEDIUM | IP loss, prompt injection risk |
| Source code | HIGH | IP loss, vulnerability exposure |

### 2.2 Threat Actors

| Actor | Motivation | Capability |
|-------|-----------|-----------|
| Opportunistic attacker | Financial gain (ransomware) | Low–Medium |
| Competitor | Competitive intelligence | Medium |
| Disgruntled employee | Sabotage, data theft | Medium (insider access) |
| State actor | Strategic intelligence | High |
| Supply chain attacker | Indirect access via dependencies | Medium–High |

### 2.3 OWASP Top 10 Mitigation Matrix

| Vulnerability | Control |
|--------------|---------|
| A01: Broken Access Control | Supabase RLS + RBAC + ABAC on every resource |
| A02: Cryptographic Failures | AES-256 at rest, TLS 1.3 in transit, no MD5/SHA1 |
| A03: Injection | ORM (Prisma/Drizzle), parameterised queries, input validation |
| A04: Insecure Design | Threat modelling per domain, security design reviews |
| A05: Security Misconfiguration | IaC (Terraform), automated config scanning, Vault |
| A06: Vulnerable Components | Snyk + Dependabot, weekly scans, SBOM maintained |
| A07: Auth Failures | Supabase Auth, MFA, short JWT expiry, account lockout |
| A08: Integrity Failures | Signed releases, subresource integrity, blockchain audit |
| A09: Logging Failures | Centralised logging, tamper-evident audit log |
| A10: SSRF | Allowlist for outbound requests, no user-controlled URLs |

---

## 3. Authentication Architecture

### 3.1 Authentication Flows

#### Standard User (Email/Password)
```
Client → POST /auth/login (email + password + TOTP if MFA enabled)
    → Supabase Auth validates credentials
    → Returns: access_token (JWT, 15min) + refresh_token (opaque, 7 days)
    → Client stores: access_token in memory, refresh_token in httpOnly cookie
    → On expiry: silent refresh via refresh_token
    → On logout: refresh_token revoked server-side
```

#### API Key (IoT/Programmatic)
```
Service → Request with X-API-Key header
    → API Gateway validates key hash against database
    → Checks: key not expired, not revoked, has required scopes
    → Attaches service identity to request context
    → Key rotation: automatic every 90 days (configurable)
```

#### Service-to-Service (Internal)
```
ServiceA → ServiceB (via Istio mTLS)
    → Both services present X.509 certificates (Vault PKI)
    → Istio validates cert chain
    → Additional: service JWT in Authorization header for app-level authz
```

### 3.2 Session Management

- Access token: JWT, RS256, 15-minute expiry, stored in memory only
- Refresh token: opaque random string, 7-day expiry, httpOnly cookie (SameSite=Strict)
- Concurrent sessions: maximum 5 per user (oldest evicted)
- Suspicious activity: concurrent login from 2+ geographies triggers MFA re-prompt
- Account lockout: 5 failed attempts → 15-minute lockout, 10 attempts → 24-hour lockout, admin notification

### 3.3 Multi-Factor Authentication

| Role | MFA Requirement |
|------|----------------|
| `super_admin` | Mandatory TOTP + hardware key |
| `tenant_admin` | Mandatory TOTP |
| `finance` | Mandatory TOTP |
| `project_manager` | Strongly encouraged (enforced Phase 2) |
| `engineer` | Optional |
| `client` | Optional |

---

## 4. Authorisation Architecture

### 4.1 Permission Model

```typescript
// Permission format: resource:action:scope
// Examples:
"project:read:own"          // Read own projects
"project:read:tenant"       // Read all tenant projects
"project:write:own"         // Modify own projects
"project:delete:tenant"     // Delete any project in tenant
"finance:read:all"          // Read all financial data
"admin:users:manage"        // Manage all users

// Role → Permission mapping (excerpt)
const rolePermissions = {
  project_manager: [
    "project:read:tenant",
    "project:write:tenant",
    "task:read:tenant",
    "task:write:tenant",
    "client:read:tenant",
    "finance:read:project",  // Only project financials
  ],
  engineer: [
    "project:read:assigned",
    "task:read:assigned",
    "task:write:assigned",
    "document:read:project",
    "document:write:project",
  ],
  client: [
    "project:read:own_client",
    "document:read:own_client",
    "invoice:read:own_client",
    "support:write:own_client",
  ],
};
```

### 4.2 Row-Level Security (Supabase RLS)

Every table has RLS enabled. Example:

```sql
-- Projects table
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

-- Tenant isolation (users only see their tenant's data)
CREATE POLICY "tenant_isolation" ON projects
  FOR ALL USING (tenant_id = auth.jwt() ->> 'tenant_id');

-- Clients only see their own projects
CREATE POLICY "client_projects" ON projects
  FOR SELECT USING (
    auth.jwt() ->> 'role' = 'client' AND
    client_id = auth.jwt() ->> 'client_id'
  );

-- Admins see all within tenant
CREATE POLICY "admin_full_access" ON projects
  FOR ALL USING (
    auth.jwt() ->> 'role' IN ('super_admin', 'tenant_admin')
  );
```

---

## 5. Data Protection

### 5.1 Encryption at Rest

| Data Category | Encryption Method |
|--------------|------------------|
| Database (Supabase) | AES-256 (managed by Supabase/AWS RDS) |
| S3 / Cloudflare R2 | SSE-S3 (AES-256) |
| Sensitive fields (PII, salary) | Application-level AES-256-GCM via Vault |
| Blockchain keys | HSM (Phase 2) / Vault transit engine (Phase 1) |
| Backups | AES-256, separate KMS key |

### 5.2 PII Fields (Encrypted at Application Layer)

```typescript
// Fields requiring additional application-level encryption:
const PII_ENCRYPTED_FIELDS = [
  'employee.idNumber',          // SA ID number
  'employee.bankAccountNumber',
  'employee.taxNumber',         // SARS tax number
  'employee.salary',
  'client.vatNumber',
  'contact.mobileNumber',       // Only if personal
  'payment.cardLast4',          // PCI scope minimisation
];
```

### 5.3 POPIA Compliance (South African GDPR equivalent)

| Requirement | Implementation |
|-------------|---------------|
| Lawful processing | Purpose documented per data type |
| Data minimisation | Collect only what is needed |
| Data subject rights | Delete/export API endpoints per user |
| Retention | Automatic deletion after retention period |
| Breach notification | Automated detection + 72-hour notification workflow |
| Data residency | All data stored in AWS af-south-1 (Cape Town) |
| Consent management | Explicit consent captured and logged |

### 5.4 Data Retention Policy

| Data Type | Retention Period | Action on Expiry |
|-----------|-----------------|-----------------|
| Financial records | 7 years (tax law) | Archive to cold storage |
| Project documents | 10 years (liability) | Archive |
| Compliance certificates | 10 years | Archive |
| Employee records | 5 years post-termination | Delete |
| Chat messages | 3 years | Delete (except compliance channels) |
| Audit logs | 7 years | Archive |
| AI conversation logs | 1 year | Delete |
| Session logs | 90 days | Delete |

---

## 6. Network Security

### 6.1 Network Topology

```
Internet
    ↓
Cloudflare (WAF, DDoS, CDN, Workers)
    ↓
AWS Route 53 + ACM (DNS + TLS termination)
    ↓
AWS Application Load Balancer
    ↓
Istio Ingress Gateway (mTLS enforcement)
    ↓
Kubernetes Services (internal cluster)
    ↓ (inter-service communication)
Istio Service Mesh (mTLS everywhere)
```

### 6.2 Firewall Rules

- No direct public access to any database (databases are in private subnets)
- All inbound traffic via Cloudflare only (AWS security groups whitelist Cloudflare IPs)
- Outbound: allowlist of approved external endpoints (payment gateways, SMS providers, etc.)
- Internal: services communicate only on defined ports; no catch-all rules

### 6.3 DDoS Protection

- Layer 3/4: Cloudflare Magic Transit
- Layer 7: Cloudflare WAF with custom rules
- Rate limiting: 100 req/min unauthenticated, 1,000 req/min authenticated
- Geo-blocking: available per tenant configuration
- Bot management: Cloudflare Bot Management (challenge suspicious bots)

---

## 7. Secrets Management

### 7.1 HashiCorp Vault Architecture

```
Vault (HA Cluster, 3 nodes)
├── Auth Methods
│   ├── Kubernetes (service accounts → Vault tokens)
│   ├── GitHub (developer access)
│   └── LDAP (enterprise directory, Phase 2)
├── Secret Engines
│   ├── KV v2 (static secrets)
│   ├── Database (dynamic database credentials)
│   ├── PKI (certificate authority for mTLS)
│   ├── Transit (encryption as a service)
│   └── AWS (dynamic IAM credentials)
└── Policies
    └── Least-privilege per service
```

### 7.2 Secret Rotation Schedule

| Secret Type | Rotation Frequency | Method |
|------------|-------------------|--------|
| Database passwords | Every 24 hours | Vault dynamic secrets |
| JWT signing keys | Every 30 days | Automated |
| API keys (external) | Every 90 days | Alert + manual |
| TLS certificates | Every 90 days | Vault PKI auto-renew |
| Blockchain signing keys | Every 180 days | Controlled ceremony |

---

## 8. Incident Response

### 8.1 Severity Classification

| Severity | Definition | Response Time | Examples |
|----------|-----------|--------------|----------|
| P0 — Critical | Data breach, production down | 15 minutes | Database exposed, ransomware |
| P1 — High | Significant service degradation | 1 hour | Authentication down, payment failing |
| P2 — Medium | Partial functionality impacted | 4 hours | Specific module broken |
| P3 — Low | Minor issue, workaround exists | 24 hours | UI bug, slow query |

### 8.2 Incident Response Playbook (P0)

```
DETECT
    → Automated: SIEM alert, anomaly detection, uptime monitor
    → Manual: customer report, staff observation

CONTAIN (within 15 minutes)
    → Isolate affected services (kill switch available in admin panel)
    → Revoke suspected compromised credentials
    → Block suspicious IP ranges in Cloudflare
    → Notify Security Lead + CTO

ASSESS (within 1 hour)
    → Determine scope: what data, how many users affected
    → Preserve evidence: snapshot logs, do not delete anything
    → Engage external forensics if required

NOTIFY
    → Internal: all-hands Slack #incident channel
    → POPIA: notify Information Regulator within 72 hours if PII involved
    → Clients: within 24 hours if their data affected
    → Public: if reputationally required

REMEDIATE
    → Fix root cause
    → Deploy fix to staging → production
    → Verify fix effective

POST-INCIDENT
    → Post-mortem within 5 business days
    → Blameless RCA document
    → Action items tracked to completion
    → Update threat model
```

---

## 9. Security Testing Schedule

| Activity | Frequency | Responsible |
|----------|-----------|------------|
| SAST (SonarQube + Snyk) | Every PR | CI/CD automated |
| Dependency scan | Weekly | Dependabot + Snyk |
| DAST (OWASP ZAP) | Weekly on staging | CI/CD automated |
| Container scan (Trivy) | Every build | CI/CD automated |
| Smart contract audit | Before each mainnet deploy | External firm |
| Penetration test | Annually + post-major-release | External firm |
| Red team exercise | Annually | External firm |
| Security architecture review | Quarterly | Internal + external |
| Phishing simulation | Quarterly | Security team |

---

*Security is everyone's responsibility. Report suspected vulnerabilities to security@beie.co.za. Do not disclose publicly before coordinated disclosure.*
