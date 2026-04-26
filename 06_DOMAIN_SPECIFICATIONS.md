# BEIE Nexus — Domain Specifications
**Document:** DOM-001 | **Version:** 1.0.0  
**Covers:** E-Commerce · Project Management · ERP · Nexus Chat · Blockchain

---

## 1. E-Commerce Platform Specification

### 1.1 Product Catalogue

#### Product Categories (E&I Sector)

```
Catalogue/
├── Electrical
│   ├── Circuit Protection (MCBs, RCDs, isolators, surge protection)
│   ├── Distribution Boards (DB boards, enclosures, busbars)
│   ├── Wiring & Cables (multicore, SWA, flex, XLPE, fire-rated)
│   ├── Cable Management (conduit, trunking, ladders, trays)
│   ├── Switchgear (contactors, overloads, starters, soft starters)
│   ├── Transformers (HV/LV distribution, isolation, auto)
│   ├── Power Quality (UPS, AVRs, power factor correction)
│   ├── Lighting (LED commercial, industrial, hazardous area, emergency)
│   ├── Motors & Drives (VFDs, servo, stepper)
│   └── Tools & Testing (multimeters, clamp meters, insulation testers)
├── Instrumentation
│   ├── Measurement — Flow (electromagnetic, Coriolis, ultrasonic, vortex)
│   ├── Measurement — Pressure (transmitters, gauges, switches)
│   ├── Measurement — Temperature (RTDs, thermocouples, transmitters)
│   ├── Measurement — Level (radar, ultrasonic, float, DP)
│   ├── Measurement — Analytical (pH, conductivity, dissolved oxygen)
│   ├── Control Valves (pneumatic, electric, solenoid)
│   ├── Actuators (pneumatic, electric, smart positioners)
│   └── Signal Conditioning (isolators, converters, multiplexers)
├── Automation & Control
│   ├── PLCs (Siemens S7, Allen-Bradley, Schneider Modicon)
│   ├── SCADA & HMI (Ignition, Wonderware, Siemens SCADA)
│   ├── I/O Modules (digital, analogue, safety)
│   ├── Industrial Networks (Profibus, Profinet, EtherNet/IP, Modbus)
│   ├── Remote I/O & RTUs
│   └── Safety Systems (safety relays, SIS components)
├── Building Automation
│   ├── BMS Controllers (DDC, modular, unitary)
│   ├── HVAC Controls (thermostats, VAV controllers, actuators)
│   ├── Sensors (temperature, humidity, CO2, occupancy, light)
│   └── Building Networks (BACnet, LonWorks, KNX devices)
├── Renewable Energy
│   ├── Solar PV (panels, strings, combiners)
│   ├── Inverters (string, central, hybrid, off-grid)
│   ├── Battery Storage (lithium, lead-acid, BMS)
│   ├── Solar Monitoring (string monitors, weather stations)
│   └── Mounting Systems (roof, ground, carport)
└── Safety & Security
    ├── Fire Detection (detectors, panels, call points, sounders)
    ├── Access Control (readers, controllers, credentials)
    ├── CCTV (cameras, NVRs, DVRs, storage)
    └── Intrusion Detection (sensors, panels, keypads)
```

#### Product Data Schema (MongoDB)

```typescript
interface Product {
  _id: ObjectId;
  sku: string;              // BEIE-[CATEGORY]-[SEQ] e.g. BEIE-CB-00142
  name: string;
  slug: string;
  description: {
    short: string;          // Max 160 chars (for listing cards)
    full: string;           // Rich text (for product page)
    technical: string;      // Technical specification text
  };
  category: {
    l1: string;             // Top level: "Electrical"
    l2: string;             // "Circuit Protection"
    l3?: string;            // "MCBs"
  };
  brand: string;            // Siemens, Schneider, ABB, etc.
  model: string;            // Manufacturer model number
  manufacturerPartNumber: string;
  pricing: {
    cost: number;           // Our cost (encrypted at rest)
    listPrice: number;      // Standard price (ex VAT)
    tiers: PriceTier[];     // Volume pricing brackets
    currency: 'ZAR';
    vatRate: 0.15;          // South African VAT
  };
  inventory: {
    inStock: boolean;
    quantity: number;
    warehouse: string;
    leadTimeDays: number;   // If not in stock
    reorderPoint: number;
  };
  specifications: Record<string, string>; // Key-value spec sheet
  documents: {
    datasheet?: string;     // IPFS hash or URL
    manual?: string;
    certifications: string[]; // SABS, CE, UL marks
    safetyDataSheet?: string;
  };
  images: ProductImage[];
  variants?: ProductVariant[]; // e.g. different ratings
  relatedProducts: string[];   // SKUs
  tags: string[];
  compliance: {
    sans?: string[];         // Relevant SANS standards
    hazardousArea?: string;  // ATEX zone if applicable
    ipRating?: string;       // e.g. IP65
  };
  status: 'active' | 'discontinued' | 'coming_soon';
  createdAt: Date;
  updatedAt: Date;
  searchIndex: string;       // Denormalised search string
}

interface PriceTier {
  minQty: number;
  maxQty: number | null;
  price: number;
  label: string;            // e.g. "10–49 units"
}
```

### 1.2 Order Management States

```
Quote Request
    → Quote Generated (AI-assisted)
        → Quote Approved by Client
            → Purchase Order Received
                → Order Confirmed
                    → Payment Received
                        → Picking & Packing
                            → Dispatched
                                → Delivered
                                    → Invoice Closed
                                        → [Blockchain: OrderFinalized]
```

### 1.3 Pricing Engine Rules

1. Base price: `product.pricing.listPrice`
2. Apply client tier discount (negotiated, stored in client profile)
3. Apply volume tier if quantity qualifies
4. Apply project discount if linked to active BEIE project
5. Apply promotional code if valid
6. Calculate VAT (15%)
7. Calculate delivery (weight × zone matrix, waived above R5,000)
8. Final price = base × (1 - discount%) + delivery + VAT

---

## 2. Project Management Specification

### 2.1 Project Lifecycle States

```
Lead / Enquiry
    → Feasibility Study
        → Proposal Issued
            → Negotiation
                → Contract Signed [Blockchain anchor]
                    → Mobilisation
                        → Active (in phases)
                            → Defects Liability Period
                                → Final Account
                                    → Closed [Blockchain anchor]
```

### 2.2 Project Data Model

```typescript
interface Project {
  id: string;                   // UUID v7
  code: string;                 // BEIE-[YEAR]-[SEQ] e.g. BEIE-2026-0042
  name: string;
  client: ClientRef;
  sector: 'commercial' | 'industrial' | 'residential' | 'renewable';
  type: ProjectType;
  status: ProjectStatus;
  
  team: {
    projectManager: UserRef;
    engineer: UserRef;
    technicians: UserRef[];
    client_contact: ContactRef;
  };
  
  dates: {
    enquiry: Date;
    contractSigned?: Date;
    startDate?: Date;
    targetCompletion?: Date;
    actualCompletion?: Date;
    defectsExpiry?: Date;
  };
  
  financials: {
    contractValue: number;      // ZAR ex VAT
    invoicedToDate: number;
    receivedToDate: number;
    costToDate: number;
    forecastFinalCost: number;
    retentionPercentage: number;
    retentionAmount: number;
  };
  
  phases: Phase[];
  documents: Document[];
  compliance: ComplianceRecord[];
  blockchainRefs: string[];     // Polygon CDK tx hashes
  
  site: {
    address: Address;
    gps: { lat: number; lng: number };
    erf: string;                // Property erf number
  };
}

interface Phase {
  id: string;
  name: string;
  sequence: number;
  status: PhaseStatus;
  tasks: Task[];
  milestones: Milestone[];
  progressPercent: number;
  startDate: Date;
  endDate: Date;
  completionDate?: Date;
}

interface Task {
  id: string;
  title: string;
  description: string;
  assignee: UserRef;
  status: 'backlog' | 'todo' | 'in_progress' | 'review' | 'done' | 'blocked';
  priority: 'low' | 'medium' | 'high' | 'critical';
  estimatedHours: number;
  actualHours: number;
  dueDate: Date;
  dependencies: string[];      // Task IDs
  subtasks: Subtask[];
  attachments: Attachment[];
  comments: Comment[];
  tags: string[];
  blockReason?: string;        // If status === 'blocked'
}

interface Milestone {
  id: string;
  name: string;
  description: string;
  dueDate: Date;
  completionDate?: Date;
  status: 'upcoming' | 'due' | 'completed' | 'overdue';
  invoiceTrigger: boolean;     // Does this trigger an invoice?
  invoicePercentage?: number;  // % of contract value
  blockchainRef?: string;      // Anchored on completion
  approvedBy?: UserRef;
}
```

### 2.3 Project Dashboard Features (Monday.com-inspired)

| View | Description |
|------|-------------|
| Board (Kanban) | Tasks as cards in swimlane columns by status |
| List | Dense table view with all task fields, inline editing |
| Gantt | Timeline with dependencies, critical path highlighted |
| Calendar | Tasks and milestones on calendar grid |
| Map | Project sites on Leaflet map with status pins |
| Dashboard | KPI widgets: budget, progress, overdue tasks, team workload |
| Workload | Resource capacity view — hours per person per week |

### 2.4 Automation Rules (Monday.com-inspired)

Users can configure rules:
```
WHEN [trigger] → IF [condition] → THEN [action]

Triggers: status changes, date arrives, field changes, task created
Conditions: assignee is, priority is, project sector is
Actions: notify user, change status, create task, send email, post to channel, trigger AI agent
```

---

## 3. ERP Core Specification

### 3.1 Financial Module

#### Chart of Accounts (BEIE Standard)

```
1000 — ASSETS
  1100 — Current Assets
    1110 — Cash & Cash Equivalents
    1120 — Accounts Receivable
    1130 — Inventory
    1140 — Work in Progress (WIP)
    1150 — Prepaid Expenses
  1200 — Non-Current Assets
    1210 — Property, Plant & Equipment
    1220 — Vehicles (Fleet)
    1230 — Equipment & Tools
    1240 — Accumulated Depreciation
    1250 — Right-of-Use Assets (IFRS 16)

2000 — LIABILITIES
  2100 — Current Liabilities
    2110 — Accounts Payable
    2120 — VAT Payable (SARS)
    2130 — PAYE Payable
    2140 — UIF Payable
    2150 — SDL Payable
    2160 — Accrued Expenses
  2200 — Non-Current Liabilities
    2210 — Loans Payable

3000 — EQUITY
  3100 — Share Capital
  3200 — Retained Earnings

4000 — REVENUE
  4100 — Project Revenue (Commercial)
  4200 — Project Revenue (Industrial)
  4300 — Project Revenue (Residential)
  4400 — SLA/Maintenance Revenue
  4500 — Product Sales Revenue
  4600 — Consulting Revenue

5000 — COST OF SALES
  5100 — Materials & Equipment
  5200 — Subcontractor Costs
  5300 — Direct Labour

6000 — OPERATING EXPENSES
  6100 — Employee Costs
  6200 — Vehicle & Fleet
  6300 — Premises & Utilities
  6400 — Marketing & Business Development
  6500 — Professional Fees
  6600 — Insurance
  6700 — IT & Technology
  6800 — Training & Development
  6900 — Depreciation & Amortisation
```

#### South African Tax Compliance

| Tax | Description | Implementation |
|-----|-------------|---------------|
| VAT (15%) | Standard rate on all taxable supplies | Auto-calculated on all invoices |
| PAYE | Employee income tax | Monthly payroll engine |
| UIF | 1% employer + 1% employee | Payroll deduction |
| SDL | 1% of payroll (if > R500k pa) | Monthly levy |
| CIT | 27% corporate income tax | Quarterly provision |
| Provisional Tax | Bi-annual prepayment of CIT | Calendar alerts |

### 3.2 HR Module

#### Employee Lifecycle States

```
Applicant → Offer Extended → Hired → Onboarding → Active
                                                       → Leave of Absence
                                                       → Performance Managed
                                                       → Terminated
                                                       → Retired
```

#### Leave Types (BCEA Compliant)

| Leave Type | Entitlement | Notes |
|------------|-------------|-------|
| Annual Leave | 21 consecutive days / year | BCEA minimum |
| Sick Leave | 30 days / 3-year cycle | BCEA minimum |
| Family Responsibility | 3 days / year | BCEA minimum |
| Maternity | 4 consecutive months | BCEA minimum |
| Parental | 10 consecutive days | BCEA minimum |
| Adoption | 10 consecutive days | BCEA |
| Study Leave | Per employment contract | As agreed |
| Unpaid Leave | As agreed | Requires approval |

### 3.3 Asset Management

```typescript
interface Asset {
  id: string;
  assetNumber: string;         // BEIE-AST-[SEQ]
  category: 'vehicle' | 'equipment' | 'tools' | 'ict' | 'furniture';
  name: string;
  make: string;
  model: string;
  serialNumber: string;
  registrationNumber?: string; // Vehicles
  
  acquisition: {
    date: Date;
    cost: number;
    supplier: string;
    purchaseOrder: string;
  };
  
  depreciation: {
    method: 'straight_line' | 'reducing_balance';
    usefulLifeYears: number;
    residualValue: number;
    ratePercent: number;
    currentBookValue: number;
  };
  
  maintenance: {
    lastService: Date;
    nextService: Date;
    serviceIntervalMonths: number;
    warrantyExpiry?: Date;
    maintenanceHistory: MaintenanceRecord[];
  };
  
  assignment: {
    assignedTo?: UserRef;
    project?: ProjectRef;
    location: string;
  };
  
  status: 'in_service' | 'under_maintenance' | 'disposed' | 'lost_stolen';
  blockchainRef?: string;      // Asset register anchored on Polygon CDK
}
```

---

## 4. Nexus Chat Specification

### 4.1 Workspace Architecture

```
Organisation (Tenant)
└── Workspace (e.g., "BEIE Internal", "BEIE + ClientName")
    ├── Channels
    │   ├── #general (mandatory, cannot be deleted)
    │   ├── #announcements (admin-post only)
    │   ├── #project-[code] (auto-created per project)
    │   ├── #team-[department]
    │   └── [user-created channels]
    ├── Direct Messages
    └── Group DMs (up to 8 participants)
```

### 4.2 Message Types

| Type | Description |
|------|-------------|
| Text | Markdown-formatted text |
| File | Image, PDF, drawing, any file < 100MB |
| Thread | Reply in thread to any message |
| System | Auto-generated (project created, milestone completed, etc.) |
| Bot | From AI agents (EstimatingAgent, ComplianceAgent, etc.) |
| Approval Request | AI HITL gate surfaced in chat |
| Blockchain Proof | Clickable verification link for anchored events |

### 4.3 Presence & Status

- `online` — active in last 5 minutes
- `away` — active in last 30 minutes
- `offline` — not active
- Custom statuses: e.g., "On site: BEIE-2026-0042", "In meeting"

### 4.4 Notifications

- Push notifications: mobile + desktop
- Email digest: configurable (immediate, hourly, daily)
- Quiet hours: user-defined, timezone-aware
- @channel: notifies all members (permission-controlled)
- @here: notifies online members only
- @[username]: direct mention

---

## 5. Blockchain Specification (Nexus Chain)

### 5.1 Smart Contracts

#### ProjectRegistry.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ProjectRegistry is AccessControl, ReentrancyGuard {
    bytes32 public constant RECORDER_ROLE = keccak256("RECORDER_ROLE");
    
    struct ProjectRecord {
        string projectCode;
        bytes32 dataHash;        // SHA-256 of project data
        string ipfsCid;          // IPFS CID of full record
        address recorder;
        uint256 timestamp;
        string eventType;        // "CREATED", "MILESTONE", "CLOSED"
    }
    
    mapping(string => ProjectRecord[]) public projectHistory;
    
    event ProjectEvent(
        string indexed projectCode,
        string eventType,
        bytes32 dataHash,
        string ipfsCid,
        address recorder,
        uint256 timestamp
    );
    
    function recordEvent(
        string calldata projectCode,
        bytes32 dataHash,
        string calldata ipfsCid,
        string calldata eventType
    ) external onlyRole(RECORDER_ROLE) nonReentrant {
        ProjectRecord memory record = ProjectRecord({
            projectCode: projectCode,
            dataHash: dataHash,
            ipfsCid: ipfsCid,
            recorder: msg.sender,
            timestamp: block.timestamp,
            eventType: eventType
        });
        
        projectHistory[projectCode].push(record);
        
        emit ProjectEvent(
            projectCode,
            eventType,
            dataHash,
            ipfsCid,
            msg.sender,
            block.timestamp
        );
    }
    
    function getHistory(string calldata projectCode) 
        external view returns (ProjectRecord[] memory) {
        return projectHistory[projectCode];
    }
}
```

### 5.2 Client-Facing Verification

Every client-facing document (CoC, invoice, milestone certificate) includes:
- QR code linking to `verify.beie.co.za/[tx-hash]`
- Verification page shows: document hash, timestamp, who recorded it, IPFS link
- Client can independently verify on Polygon explorer
- "Powered by Nexus Chain" branding on all verified documents

---

*Domain specifications continue to evolve. Changes require an Architecture Decision Record and product owner approval.*
