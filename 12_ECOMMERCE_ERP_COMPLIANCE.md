# BEIE Nexus — E-Commerce, ERP Integration & Compliance Engine
**Document:** ECOM-001 | **Version:** 1.0.0

---

## 1. E-Commerce Platform — Full Specification

### 1.1 Storefront Architecture (Next.js)

```
apps/web-public/src/
├── app/
│   ├── (marketing)/              # Marketing pages (RSC, no auth)
│   │   ├── page.tsx              # Homepage (corporate website)
│   │   ├── about/page.tsx
│   │   ├── services/page.tsx
│   │   ├── sectors/page.tsx
│   │   └── contact/page.tsx
│   ├── (shop)/                   # E-commerce (RSC + client components)
│   │   ├── layout.tsx            # Shop shell: header, cart drawer, footer
│   │   ├── page.tsx              # Shop homepage: featured, categories
│   │   ├── products/
│   │   │   ├── page.tsx          # Catalogue listing (ISR, 60s revalidate)
│   │   │   └── [sku]/page.tsx    # Product detail (ISR, 300s revalidate)
│   │   ├── categories/
│   │   │   └── [...slug]/page.tsx # Category pages
│   │   ├── search/page.tsx       # Search results
│   │   ├── cart/page.tsx
│   │   └── checkout/
│   │       ├── page.tsx          # Checkout orchestrator
│   │       ├── delivery/page.tsx
│   │       └── payment/page.tsx
│   ├── (auth)/                   # Auth flows
│   │   ├── login/page.tsx
│   │   ├── register/page.tsx
│   │   └── verify/page.tsx
│   ├── (account)/                # Authenticated customer area
│   │   ├── orders/page.tsx
│   │   ├── quotes/page.tsx
│   │   └── profile/page.tsx
│   └── api/                      # Next.js Route Handlers
│       ├── webhooks/peach/route.ts
│       └── revalidate/route.ts
├── components/
│   ├── catalogue/
│   │   ├── ProductCard.tsx
│   │   ├── ProductGrid.tsx
│   │   ├── ProductDetail.tsx
│   │   ├── ProductImages.tsx
│   │   ├── SpecificationTable.tsx
│   │   └── RelatedProducts.tsx
│   ├── cart/
│   │   ├── CartDrawer.tsx
│   │   ├── CartItem.tsx
│   │   └── CartSummary.tsx
│   ├── checkout/
│   │   ├── CheckoutStepper.tsx
│   │   ├── DeliveryForm.tsx
│   │   ├── PaymentForm.tsx      # Peach Payments hosted fields
│   │   └── OrderConfirmation.tsx
│   └── search/
│       ├── SearchBar.tsx
│       ├── SearchResults.tsx
│       └── FilterPanel.tsx
└── lib/
    ├── catalogue.ts              # MongoDB Atlas API calls
    ├── cart.ts                   # Cart state management
    ├── checkout.ts               # Checkout flow logic
    └── search.ts                 # Search orchestration
```

### 1.2 Product Search Architecture

```typescript
// Three-layer search strategy
class ProductSearchService {
  
  // Layer 1: Exact & structured (fast, for known queries)
  async exactSearch(filters: ProductFilters): Promise<Product[]> {
    return this.mongoClient
      .db('beie_catalogue')
      .collection('products')
      .find({
        status: 'active',
        ...(filters.category && { 'category.l1': filters.category }),
        ...(filters.brand && { brand: filters.brand }),
        ...(filters.inStock && { 'inventory.inStock': true }),
        ...(filters.priceMin && { 'pricing.listPrice': { $gte: filters.priceMin } }),
        ...(filters.priceMax && { 'pricing.listPrice': { $lte: filters.priceMax } }),
      })
      .sort({ [filters.sortBy || 'name']: 1 })
      .skip((filters.page - 1) * filters.perPage)
      .limit(filters.perPage)
      .toArray();
  }
  
  // Layer 2: Full-text (MongoDB Atlas Search)
  async fullTextSearch(query: string, filters: ProductFilters): Promise<Product[]> {
    return this.mongoClient
      .db('beie_catalogue')
      .collection('products')
      .aggregate([
        {
          $search: {
            index: 'product_text_search',
            compound: {
              must: [{
                text: {
                  query,
                  path: ['name', 'description.short', 'searchIndex'],
                  fuzzy: { maxEdits: 1 },
                }
              }],
              filter: [
                { equals: { path: 'status', value: 'active' } },
                ...(filters.category ? [{ 
                  equals: { path: 'category.l1', value: filters.category }
                }] : []),
              ]
            }
          }
        },
        { $addFields: { score: { $meta: 'searchScore' } } },
        { $sort: { score: -1 } },
        { $skip: (filters.page - 1) * filters.perPage },
        { $limit: filters.perPage },
      ])
      .toArray();
  }
  
  // Layer 3: Semantic/vector (AI-powered, for complex queries)
  async semanticSearch(query: string): Promise<Product[]> {
    // Generate embedding for the query
    const embedding = await this.embeddingService.embed(query);
    
    // Atlas Vector Search
    return this.mongoClient
      .db('beie_catalogue')
      .collection('products')
      .aggregate([{
        $vectorSearch: {
          index: 'product_vector_search',
          path: 'embedding',
          queryVector: embedding,
          numCandidates: 100,
          limit: 20,
          filter: { status: { $eq: 'active' } },
        }
      }])
      .toArray();
  }
  
  // Orchestrate: route to appropriate strategy
  async search(query: string, filters: ProductFilters): Promise<SearchResult> {
    const isSimpleFilter = !query || query.length < 2;
    const isComplexQuery = query.length > 30 || query.includes('?');
    
    if (isSimpleFilter) return this.exactSearch(filters);
    if (isComplexQuery) return this.semanticSearch(query);
    
    // Default: full-text + exact filter combination
    const [textResults, exactResults] = await Promise.all([
      this.fullTextSearch(query, filters),
      this.exactSearch(filters),
    ]);
    
    return this.mergeAndRank(textResults, exactResults);
  }
}
```

### 1.3 Quoting System (B2B)

For large orders, BEIE requires a formal quote process:

```
Client requests quote (cart or direct)
    ↓
EstimatingAgent generates preliminary pricing
    → Applies client-tier discount
    → Checks inventory lead times
    → Calculates delivery
    → Flags any non-standard items
    ↓
HITL: Sales/BD reviews and adjusts AI quote
    ↓
Formal quote PDF generated (with 30-day validity)
    → Blockchain anchored (quote hash)
    → Emailed to client
    ↓
Client accepts → PO received → Order created
Client declines → Closed
Client counters → Revision loop
```

### 1.4 Payment Gateway Integration

```typescript
// Peach Payments (primary — South African)
class PeachPaymentsAdapter implements PaymentAdapter {
  async createCheckout(order: Order): Promise<CheckoutSession> {
    const response = await fetch(`${this.baseUrl}/v1/checkouts`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.secretKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        amount: order.totalInclVat.toFixed(2),
        currency: 'ZAR',
        merchantTransactionId: order.id,
        customer: {
          email: order.customer.email,
          givenName: order.customer.firstName,
          surname: order.customer.lastName,
        },
        billing: order.billingAddress,
        paymentType: 'DB',
        brands: ['VISA', 'MASTER', 'AMEX', 'PAYFLEX', 'OZOW'],
        notificationUrl: `${this.webhookBase}/api/webhooks/peach`,
        shopperResultUrl: `${this.frontendBase}/checkout/result`,
      }),
    });
    return response.json();
  }
  
  async handleWebhook(payload: PeachWebhookPayload): Promise<void> {
    // Verify HMAC signature
    this.verifySignature(payload);
    
    if (payload.result.code.startsWith('000.')) {
      // Payment successful
      await this.orderService.markPaid(payload.merchantTransactionId, {
        amount: payload.amount,
        reference: payload.id,
        method: payload.paymentBrand,
      });
      
      // Trigger blockchain anchor
      await this.eventPublisher.publish(KAFKA_TOPICS.ORDER_PAID, {
        orderId: payload.merchantTransactionId,
        amount: payload.amount,
        reference: payload.id,
      });
    }
  }
}

// Stripe (fallback — international)
class StripeAdapter implements PaymentAdapter {
  // Standard Stripe integration as fallback
}
```

---

## 2. ERP Integration Specification

### 2.1 Automatic Journal Entry Generation

When business events occur, journals are auto-generated:

```kotlin
// Kotlin/Spring — Journal entry automation
@Service
class JournalAutomationService(
    private val journalRepository: JournalRepository,
    private val accountService: AccountService,
) {

    // When invoice is issued
    @EventListener
    fun onInvoiceIssued(event: InvoiceIssuedEvent) {
        val invoice = event.invoice
        val journal = JournalEntry(
            description = "Invoice ${invoice.invoiceNumber} — ${invoice.clientName}",
            reference = invoice.invoiceNumber,
            entryDate = invoice.issueDate,
            source = "INVOICE",
            sourceId = invoice.id,
            lines = listOf(
                // Debit: Accounts Receivable
                JournalLine(
                    accountCode = "1120",
                    description = "AR — ${invoice.clientName}",
                    debit = invoice.totalInclVat,
                    credit = BigDecimal.ZERO,
                ),
                // Credit: Revenue (per sector)
                JournalLine(
                    accountCode = invoice.revenueAccount, // e.g., "4100"
                    description = "Revenue — ${invoice.projectCode}",
                    debit = BigDecimal.ZERO,
                    credit = invoice.subtotalExclVat,
                ),
                // Credit: VAT Output
                JournalLine(
                    accountCode = "2120",
                    description = "VAT Output",
                    debit = BigDecimal.ZERO,
                    credit = invoice.vatAmount,
                ),
            )
        )
        journalRepository.save(journal)
    }

    // When payment received
    @EventListener
    fun onPaymentReceived(event: PaymentReceivedEvent) {
        val payment = event.payment
        journalRepository.save(JournalEntry(
            description = "Payment received — ${payment.reference}",
            lines = listOf(
                JournalLine(accountCode = "1110", debit = payment.amount, credit = BigDecimal.ZERO),
                JournalLine(accountCode = "1120", debit = BigDecimal.ZERO, credit = payment.amount),
            )
        ))
    }
}
```

### 2.2 South African Payroll Engine

```kotlin
@Service
class PayrollEngineService {
    
    data class PayrollSlip(
        val employee: Employee,
        val period: YearMonth,
        val grossSalary: BigDecimal,
        val payeDeduction: BigDecimal,
        val uifEmployee: BigDecimal,
        val uifEmployer: BigDecimal,
        val sdl: BigDecimal,
        val otherDeductions: List<Deduction>,
        val netPay: BigDecimal,
        val costToCompany: BigDecimal,
    )
    
    fun calculatePayroll(employee: Employee, period: YearMonth): PayrollSlip {
        val gross = employee.monthlySalary
        
        // PAYE (progressive — 2026/27 tax tables)
        val paye = calculatePAYE(gross * 12, employee.taxRebate) / 12
        
        // UIF — 1% employee, 1% employer (capped at R17,712 pa / R1,476/month)
        val uifBase = minOf(gross, BigDecimal("17712").divide(BigDecimal("12")))
        val uifEmployee = uifBase * BigDecimal("0.01")
        val uifEmployer = uifBase * BigDecimal("0.01")
        
        // SDL — 1% of gross (if annual payroll > R500,000)
        val sdl = if (isSDLObligated()) gross * BigDecimal("0.01") else BigDecimal.ZERO
        
        // Other deductions (medical aid, pension, etc.)
        val otherDeductions = employee.deductions
        
        val netPay = gross - paye - uifEmployee - otherDeductions.sumOf { it.amount }
        val ctc = gross + uifEmployer + sdl
        
        return PayrollSlip(
            employee = employee,
            period = period,
            grossSalary = gross,
            payeDeduction = paye,
            uifEmployee = uifEmployee,
            uifEmployer = uifEmployer,
            sdl = sdl,
            otherDeductions = otherDeductions,
            netPay = netPay,
            costToCompany = ctc,
        )
    }
    
    // 2026/27 SARS tax tables (update annually)
    private fun calculatePAYE(annualIncome: BigDecimal, rebate: BigDecimal): BigDecimal {
        val tax = when {
            annualIncome <= BigDecimal("237100")  -> annualIncome * BigDecimal("0.18")
            annualIncome <= BigDecimal("370500")  -> BigDecimal("42678") + (annualIncome - BigDecimal("237100")) * BigDecimal("0.26")
            annualIncome <= BigDecimal("512800")  -> BigDecimal("77362") + (annualIncome - BigDecimal("370500")) * BigDecimal("0.31")
            annualIncome <= BigDecimal("673000")  -> BigDecimal("121475") + (annualIncome - BigDecimal("512800")) * BigDecimal("0.36")
            annualIncome <= BigDecimal("857900")  -> BigDecimal("179147") + (annualIncome - BigDecimal("673000")) * BigDecimal("0.39")
            annualIncome <= BigDecimal("1817000") -> BigDecimal("251258") + (annualIncome - BigDecimal("857900")) * BigDecimal("0.41")
            else                                  -> BigDecimal("644489") + (annualIncome - BigDecimal("1817000")) * BigDecimal("0.45")
        }
        return maxOf(BigDecimal.ZERO, tax - rebate)
    }
}
```

---

## 3. SANS Compliance Engine

### 3.1 ComplianceAgent Architecture

The `ComplianceAgent` uses RAG over indexed SANS 10142-1:2024 content to check electrical designs:

```python
class ComplianceAgent:
    """
    Checks electrical installation designs against SANS 10142-1:2024 Ed 3.2
    and other applicable South African standards.
    """
    
    def build_graph(self) -> StateGraph:
        graph = StateGraph(ComplianceState)
        
        graph.add_node("parse_input", self.parse_input)
        graph.add_node("retrieve_standards", self.retrieve_standards)
        graph.add_node("check_cable_sizing", self.check_cable_sizing)
        graph.add_node("check_protection", self.check_protection)
        graph.add_node("check_earthing", self.check_earthing)
        graph.add_node("check_isolation", self.check_isolation)
        graph.add_node("check_documentation", self.check_documentation)
        graph.add_node("generate_report", self.generate_report)
        graph.add_node("human_review", self.human_review_gate)
        graph.add_node("finalise", self.finalise)
        
        # Edges
        graph.add_edge("parse_input", "retrieve_standards")
        graph.add_edge("retrieve_standards", "check_cable_sizing")
        graph.add_edge("check_cable_sizing", "check_protection")
        graph.add_edge("check_protection", "check_earthing")
        graph.add_edge("check_earthing", "check_isolation")
        graph.add_edge("check_isolation", "check_documentation")
        graph.add_edge("check_documentation", "generate_report")
        
        # Always require human review for compliance
        graph.add_edge("generate_report", "human_review")
        graph.add_edge("human_review", "finalise")
        
        graph.set_entry_point("parse_input")
        return graph.compile()
    
    async def check_cable_sizing(self, state: ComplianceState) -> ComplianceState:
        """
        Checks: SANS 10142-1 Table B.1 — Current-carrying capacity
        Checks: Voltage drop < 5% (supply to point of use)
        Checks: Short-circuit capacity of protective devices
        """
        prompt = f"""
        You are checking cable sizing compliance with SANS 10142-1:2024 Ed 3.2.
        
        Design data: {state['design_data']['cables']}
        
        Standards retrieved: {state['retrieved_standards']['cable_sizing']}
        
        Check:
        1. Current-carrying capacity ≥ design current (Table B.1)
        2. Voltage drop ≤ 5% from supply to furthest point
        3. Short-circuit withstand of cables ≥ protective device let-through energy
        
        Return JSON: {{
            "compliant": bool,
            "issues": [{{
                "severity": "critical|major|minor",
                "clause": "SANS 10142-1 clause reference",
                "description": "clear description",
                "recommendation": "corrective action"
            }}],
            "confidence": float  // 0.0-1.0
        }}
        """
        result = await self.llm.ainvoke(prompt)
        state['check_results']['cable_sizing'] = result
        return state
```

### 3.2 Compliance Report Output

```markdown
# BEIE Electrical Compliance Report
**Project:** BEIE-2026-0042 — Shoprite Distribution Centre  
**Engineer:** Mr. T. Ndlovu (ECSA Pr. Eng)  
**Date:** 2026-04-26  
**Standard:** SANS 10142-1:2024 Edition 3.2  
**AI Agent:** ComplianceAgent v1.2 (Confidence: 0.91)  
**Status:** REQUIRES ATTENTION — 2 Critical, 1 Major, 3 Minor

## Critical Issues

### C01 — Cable Undersizing (Clause 5.3.2.1)
**Description:** Circuit DB3-L12 (ring main, 63A MCB) specified as 10mm² Cu.  
**SANS Requirement:** Minimum 16mm² Cu for 63A circuit in conduit (Table B.1).  
**Recommendation:** Upsize to 16mm² Cu or reduce MCB to 40A.

### C02 — RCD Missing on Socket Outlets (Clause 6.4.3)
**Description:** DB4 feeds 23 socket outlets in warehouse without 30mA RCD protection.  
**SANS Requirement:** All socket outlets ≤ 20A must be RCD-protected.  
**Recommendation:** Install 2× 63A 30mA RCCB on DB4 to cover all socket circuits.

## Major Issues
...

## Blockchain Verification
This report is anchored at: `0x7f4a...`  
Verify at: https://verify.beie.co.za/0x7f4a...

*Reviewed and approved by: [Engineer name] on [date]*
```

---

*E-Commerce and ERP specifications are living documents. Changes to financial calculation logic require Finance team sign-off.*
