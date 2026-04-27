# BEIE Nexus — AI Rules & Agentic Development Guidelines
**Document:** AI-001 | **Version:** 1.0.0 | **Status:** Enforced  
**Applies To:** All AI agents, LLM integrations, agentic development workflows

---

## 1. The Fundamental Contract

Every AI agent operating within BEIE Nexus operates under a single inviolable contract:

> **"AI proposes. Humans approve. Blockchain records."**

No autonomous AI action may affect a client, project, financial record, or compliance document without a human approval gate. This is non-negotiable and enforced at the infrastructure level, not merely at the application level.

---

## 2. Agent Classification System

### 2.1 Autonomy Tiers

| Tier | Name | Human Gate | Examples |
|------|------|-----------|---------|
| **T0** | Fully Autonomous | None | Spell-check, formatting, search |
| **T1** | Low-Touch | Notification only | Draft generation, data enrichment |
| **T2** | Approval Required | Explicit approve/reject | Quote generation, schedule changes |
| **T3** | Dual Approval | Two humans must approve | Financial commitments > R10,000 |
| **T4** | Executive Override | Executive + audit trail | Contract changes, compliance certs |

### 2.2 Agent Classification Table

| Agent | Tier | Max Autonomous Action |
|-------|------|-----------------------|
| `EstimatingAgent` | T2 | Draft quote (no send) |
| `ComplianceAgent` | T2 | Flag issues (no block) |
| `TenderAgent` | T2 | Draft document (no submit) |
| `MaintenanceAgent` | T1 | Alert technician (no dispatch) |
| `FinanceAgent` | T3 | Flag anomaly (no adjustment) |
| `DocumentAgent` | T1 | Draft (no send) |
| `CatalogueAgent` | T0 | Search, recommend, display |
| `SupportAgent` | T1 | Draft reply (no send) |
| `SchedulingAgent` | T2 | Propose (no commit) |
| `BlockchainAgent` | T3 | Queue anchor (dual confirm) |

---

## 3. Agentic Development Rules (Human-in-the-Loop Development)

### 3.1 The Development Loop

All feature development follows this cycle:

```
PLAN → AI GENERATES → HUMAN REVIEWS → HUMAN APPROVES → COMMIT → TEST → DEPLOY
```

Each step is a checkpoint. AI-generated code is never committed without human review. AI-generated architecture decisions are never implemented without documented human approval.

### 3.2 What AI May Do Autonomously in Development

**Permitted (T0 in dev context):**
- Generate boilerplate code from approved templates
- Write unit tests for specified function signatures
- Generate TypeScript types from Supabase schema
- Produce documentation from code comments
- Suggest refactors (flagged, not applied)
- Generate seed data for development databases
- Produce translation strings

**Requires Human Review (T1–T2 in dev context):**
- New API endpoint design
- Database schema changes
- New environment variable introduction
- Dependency additions
- Security-sensitive code (auth, crypto, payment)
- Smart contract changes (always T4)

### 3.3 Code Review Rules for AI-Generated Code

Every AI-generated code block must be tagged:

```typescript
// @ai-generated: claude-sonnet-4-5 | 2026-04-25
// @reviewed-by: [engineer name]
// @approved: [date]
// @confidence: [high|medium|low]
```

Low-confidence AI-generated code requires a second human reviewer.

### 3.4 Prohibited AI Actions in Development

- AI must NEVER generate or suggest credentials, API keys, or secrets
- AI must NEVER modify `.env` files or infrastructure secrets
- AI must NEVER push directly to `main` or `production` branches
- AI must NEVER modify smart contract logic without T4 approval
- AI must NEVER alter database migration files after they have run in staging

---

## 4. LLM Integration Standards

### 4.1 Primary Model Hierarchy

```
Task Routing → Complexity Classifier
    ├── Simple (< 500 tokens context) → Claude Haiku
    ├── Standard (< 4k tokens) → Claude Sonnet
    └── Complex (reasoning, long context) → Claude Opus
```

Cost optimisation: Route aggressively to Haiku for classification, extraction, and formatting tasks.

### 4.2 Prompt Engineering Standards

All production system prompts must:

1. **Define the agent's identity** — who it is and its purpose
2. **State constraints explicitly** — what it cannot do
3. **Define output format** — always structured (JSON via Instructor)
4. **Include a confidence field** — agent must self-report confidence (0.0–1.0)
5. **Reference the HITL gate** — agent must state when it would escalate
6. **Be version-controlled** — stored in `prompts/` directory, semver tagged

```python
# Standard prompt template structure
SYSTEM_PROMPT_TEMPLATE = """
# Identity
You are {agent_name}, a specialist AI agent within BEIE Nexus.
Your domain: {domain_description}

# Capabilities
{capabilities_list}

# Hard Constraints
- You NEVER {constraint_list}
- You ALWAYS escalate to a human when {escalation_triggers}
- Your confidence threshold for autonomous action: {confidence_threshold}

# Output Format
Always respond in the following JSON structure:
{output_schema}

# Escalation Protocol
If confidence < {threshold} or action_type in {escalation_types}:
  Set requires_human_approval: true
  Provide reasoning in escalation_reason field
"""
```

### 4.3 Context Window Management

- Maximum context per agent call: 128,000 tokens (Claude Opus)
- Conversation history compression: summarise after 20 turns
- RAG chunk size: 512 tokens, overlap 64 tokens
- Always include: system prompt, user context, recent history, retrieved documents

### 4.4 Hallucination Mitigation

- All product prices, compliance codes, and technical specs must be retrieved from verified internal sources (RAG), not generated
- After retrieval: include source citation in response
- For compliance-critical information: require `[VERIFIED: {source}]` tag
- Financial figures: always sourced from Supabase, never generated

---

## 5. LangGraph Workflow Rules

### 5.1 Graph Structure Standards

Every LangGraph workflow must:
- Have a clearly defined start node and terminal nodes
- Include an `error_handler` node reachable from every node
- Include a `human_review` node for T2+ actions
- Emit a NexusEvent at every node transition
- Have a maximum of 50 nodes (larger workflows must be split)
- Be fully serialisable to JSON (for pause/resume)

### 5.2 State Management

```python
class WorkflowState(TypedDict):
    workflow_id: str
    tenant_id: str
    actor_id: str
    created_at: str
    status: Literal["running", "paused", "awaiting_human", "completed", "failed"]
    current_node: str
    history: list[NodeTransition]
    context: dict[str, Any]
    human_decision: Optional[HumanDecision]
    error: Optional[WorkflowError]
    blockchain_refs: list[str]  # Anchored tx hashes
```

### 5.3 Pause and Resume Contract

Workflows requiring human input MUST:
1. Serialise full state to Supabase (`workflow_states` table)
2. Emit a `workflow.paused` event to Kafka
3. Create a notification for the designated approver
4. Set a deadline (default: 24 hours)
5. On deadline expiry: escalate to next approver tier
6. On resume: reload state and continue from exact node

---

## 6. CrewAI Multi-Agent Rules

### 6.1 Crew Structure Standard

```python
# Every crew must define:
crew = Crew(
    agents=[...],           # Explicit agent list
    tasks=[...],            # Explicit task list with dependencies
    process=Process.sequential | Process.hierarchical,
    max_rpm=10,             # Rate limit API calls
    verbose=True,           # Always verbose for audit
    output_log_file=True,   # Always log for audit
    memory=True,            # Enable crew memory
)
```

### 6.2 Inter-Agent Communication Standards

- Agents communicate only through defined task outputs
- No agent may call another agent's internal methods directly
- All inter-agent data passes through type-validated Pydantic models
- Sensitive data (PII, financials) is redacted before passing to subagents unless explicitly authorised

### 6.3 Tool Use Standards

Every tool used by an agent must:
- Have a typed input and output schema
- Implement a `dry_run` mode for testing
- Log all invocations to the audit system
- Have a timeout (default: 30 seconds)
- Have a retry policy (max 3 retries, exponential backoff)

---

## 7. RAG (Retrieval Augmented Generation) Standards

### 7.1 Knowledge Base Registry

| Knowledge Base | Source | Update Frequency | Owner |
|---------------|--------|-----------------|-------|
| Product Catalogue | MongoDB Atlas | Real-time | E-Commerce Team |
| SANS Standards | Internal docs | Monthly | Compliance Team |
| Project Templates | Supabase | On change | PM Team |
| Pricing Database | Supabase | Daily | Finance Team |
| Client History | Supabase | Real-time | CRM System |
| Technical Manuals | IPFS | On upload | Document System |

### 7.2 Retrieval Standards

- Always retrieve at least 3 chunks for any factual query
- Include chunk source, date, and confidence in response
- Cross-reference multiple sources for compliance-critical queries
- Rerank retrieved chunks using a reranker model before LLM consumption
- Cache embeddings; never re-embed unchanged documents

---

## 8. Monitoring & Observability for AI

### 8.1 Required Metrics

Every agent invocation must emit:
- `agent.invocation.count` — total calls
- `agent.invocation.latency_ms` — response time
- `agent.confidence.score` — self-reported confidence
- `agent.escalation.rate` — % requiring human review
- `agent.token.cost` — estimated cost in USD
- `agent.output.quality_score` — post-hoc scoring

### 8.2 Alerting Thresholds

| Metric | Warning | Critical |
|--------|---------|---------|
| Escalation rate | > 30% | > 60% |
| Confidence score avg | < 0.75 | < 0.60 |
| P95 latency | > 10s | > 30s |
| Error rate | > 2% | > 5% |
| Token cost (hourly) | > $50 | > $200 |

### 8.3 AI Audit Log Schema

Every AI action is logged:
```json
{
  "log_id": "uuid-v7",
  "timestamp": "ISO 8601",
  "tenant_id": "string",
  "agent_id": "string",
  "agent_version": "semver",
  "model": "claude-sonnet-4-5",
  "action_type": "string",
  "input_hash": "sha256",
  "output_hash": "sha256",
  "confidence": 0.92,
  "tokens_used": 1842,
  "cost_usd": 0.0055,
  "required_human_review": false,
  "human_reviewer_id": null,
  "human_decision": null,
  "blockchain_anchored": true,
  "blockchain_tx": "0x...",
  "duration_ms": 3420
}
```

---

## 9. AI Ethics & Governance

### 9.1 Prohibited Uses

AI within BEIE Nexus must NEVER:
- Make final employment or HR decisions without human review
- Deny a client claim autonomously
- Generate or store biometric data
- Profile users based on protected characteristics
- Generate deceptive content (fake reviews, false compliance certs)
- Operate outside its defined domain context

### 9.2 Bias Monitoring

- All client-facing AI outputs are sampled monthly for bias
- EstimatingAgent outputs are audited quarterly for pricing fairness
- Any bias finding triggers an immediate model review

### 9.3 Model Update Protocol

1. New model version identified
2. Shadow deployment (routes 5% of traffic)
3. A/B comparison metrics collected (minimum 1,000 samples)
4. Human review of sample outputs
5. Approval by AI Governance lead
6. Gradual rollout (5% → 20% → 50% → 100%)
7. Old version retained for 30 days (rollback capability)

---

*All AI agents operating in BEIE Nexus are bound by these rules. Violations are surfaced to the AI Governance dashboard and escalated to the platform administrator.*
