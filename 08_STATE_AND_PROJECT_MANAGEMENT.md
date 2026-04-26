# BEIE Nexus — State Management & Project Management Framework
**Document:** STATE-001 | **Version:** 1.0.0

---

## 1. State Management Architecture

### 1.1 Philosophy

State in BEIE Nexus is classified by **scope** and **lifetime**:

```
SERVER STATE         CLIENT STATE          LOCAL STATE
(in database)        (shared UI state)     (component state)
    ↑                     ↑                     ↑
TanStack Query        Zustand (Next.js)     React useState
Supabase Realtime     NgRx (Angular)        Angular signals
                      RxJS BehaviorSubject
```

**Rule:** Never store server state in client state managers. TanStack Query and Supabase Realtime handle all server synchronisation. Zustand/NgRx handles only UI-specific shared state (sidebar open, selected theme, active filters).

### 1.2 Angular State Architecture (Dashboard)

```typescript
// Store architecture using NgRx (Redux pattern)
// One store per domain, following the Ducks pattern

// apps/web-dashboard/src/app/store/
├── projects/
│   ├── projects.actions.ts
│   ├── projects.reducer.ts
│   ├── projects.effects.ts
│   ├── projects.selectors.ts
│   └── projects.facade.ts      // Components use facade, not store directly
├── auth/
├── notifications/
├── ui/                         // Purely UI state (sidebar, theme, etc.)
└── index.ts                    // Root store configuration
```

#### NgRx Store Shape

```typescript
interface AppState {
  auth: AuthState;
  projects: ProjectsState;
  tasks: TasksState;
  ui: UIState;
  notifications: NotificationsState;
  chat: ChatState;
  ecommerce: EcommerceState;
}

interface ProjectsState {
  entities: Record<string, Project>;
  ids: string[];
  selectedId: string | null;
  filters: ProjectFilters;
  sortBy: ProjectSortKey;
  sortOrder: 'asc' | 'desc';
  loading: boolean;
  error: ApiError | null;
  pagination: PaginationState;
}

interface UIState {
  sidebarCollapsed: boolean;
  theme: 'dark' | 'light' | 'system';
  activeView: Record<string, ViewType>; // Per-module view preferences
  commandPaletteOpen: boolean;
  notifications: UINotification[];
}
```

### 1.3 Next.js State Architecture (Public/Storefront)

```typescript
// Zustand stores (minimal — server state via TanStack Query)
// apps/web-public/src/store/

// Cart store (persisted to localStorage + server on login)
const useCartStore = create<CartState>()(
  persist(
    (set, get) => ({
      items: [],
      addItem: (product, quantity) => { ... },
      removeItem: (sku) => { ... },
      updateQuantity: (sku, quantity) => { ... },
      clearCart: () => set({ items: [] }),
      total: () => get().items.reduce(...),
    }),
    { name: 'beie-cart' }
  )
);

// UI store (not persisted)
const useUIStore = create<UIState>()((set) => ({
  mobileNavOpen: false,
  searchOpen: false,
  activeCategory: null,
  setMobileNavOpen: (open) => set({ mobileNavOpen: open }),
}));
```

### 1.4 Real-Time State Synchronisation

```typescript
// Pattern: Supabase Realtime → Local cache invalidation → UI update

// In Angular (NgRx Effect)
syncProjectRealtime$ = createEffect(() => {
  return this.supabase
    .channel('projects')
    .on('postgres_changes', 
        { event: '*', schema: 'public', table: 'projects' },
        (payload) => {
          // Dispatch action to update store
          this.store.dispatch(ProjectActions.realtimeUpdate({ payload }));
        }
    )
    .subscribe();
}, { dispatch: false });

// In Next.js (TanStack Query + Supabase)
// Supabase channel invalidates TanStack Query cache
useEffect(() => {
  const channel = supabase
    .channel('projects')
    .on('postgres_changes', { event: '*', table: 'projects' }, () => {
      queryClient.invalidateQueries({ queryKey: ['projects'] });
    })
    .subscribe();
  return () => supabase.removeChannel(channel);
}, []);
```

### 1.5 Optimistic Updates Pattern

```typescript
// For task status updates (drag-and-drop Kanban)
// Optimistic: update UI immediately, rollback on failure

const updateTaskStatus = useMutation({
  mutationFn: (update: TaskStatusUpdate) => 
    api.tasks.updateStatus(update),
  
  onMutate: async (update) => {
    // Cancel in-flight queries
    await queryClient.cancelQueries({ queryKey: ['tasks', update.projectId] });
    
    // Snapshot previous state
    const previousTasks = queryClient.getQueryData(['tasks', update.projectId]);
    
    // Optimistically update
    queryClient.setQueryData(['tasks', update.projectId], (old) =>
      old.map(task => task.id === update.id 
        ? { ...task, status: update.status } 
        : task)
    );
    
    return { previousTasks };
  },
  
  onError: (err, update, context) => {
    // Rollback on error
    queryClient.setQueryData(['tasks', update.projectId], context.previousTasks);
    toast.error('Failed to update task. Please try again.');
  },
  
  onSettled: () => {
    queryClient.invalidateQueries({ queryKey: ['tasks'] });
  },
});
```

---

## 2. Project Management Framework

### 2.1 BEIE Project Methodology

BEIE Nexus implements a hybrid **Prince2-Agile** methodology adapted for E&I engineering projects:

```
PRINCE2 STRUCTURE     +     AGILE EXECUTION
─────────────────           ───────────────
Clear governance             Sprint-based task delivery
Stage gates                  Daily standups
Risk management              Retrospectives  
Configuration mgmt           Backlog refinement
Defined roles                Kanban/Scrum boards
```

### 2.2 Standard Project Templates

Every new project is bootstrapped from a template:

#### Template: Commercial Electrical Installation

```
Phase 1: Design & Engineering (Est. 10% of project duration)
├── Milestone: Design drawings approved [Invoice trigger: 10%]
├── Task: Load schedule development
├── Task: Single line diagram
├── Task: DB board schedules
├── Task: Cable schedules
├── Task: Lighting design
├── Task: CoC application (if new installation)
└── Task: Client design approval

Phase 2: Procurement (Est. 5% of duration)
├── Milestone: Materials delivered to site [Invoice trigger: 25%]
├── Task: Bill of materials finalised
├── Task: Purchase orders raised
├── Task: Supplier lead time confirmation
└── Task: Delivery to site verified

Phase 3: Installation (Est. 60% of duration)
├── Milestone: First fix complete
├── Milestone: Second fix complete [Invoice trigger: 60%]
├── Task: Cable installation
├── Task: DB board assembly
├── Task: Wiring and terminations
├── Task: Earthing and bonding
└── Task: Conduit and trunking

Phase 4: Testing & Commissioning (Est. 20% of duration)
├── Milestone: Testing complete [Invoice trigger: 90%]
├── Task: Insulation resistance testing
├── Task: Earth loop impedance testing
├── Task: RCD testing
├── Task: Functional testing
└── Task: Thermographic survey

Phase 5: Handover (Est. 5% of duration)
├── Milestone: Handover complete [Invoice trigger: 100%]
├── Task: CoC issuance [Blockchain anchor]
├── Task: As-built drawings
├── Task: O&M manuals
├── Task: Client sign-off
└── Task: Defects list (if any)
```

### 2.3 Risk Management Framework

```typescript
interface ProjectRisk {
  id: string;
  title: string;
  description: string;
  category: 'technical' | 'commercial' | 'programme' | 'health_safety' | 'compliance';
  probability: 1 | 2 | 3 | 4 | 5;    // 1=Very Low, 5=Very High
  impact: 1 | 2 | 3 | 4 | 5;         // 1=Negligible, 5=Critical
  riskScore: number;                   // probability × impact
  owner: UserRef;
  mitigationActions: MitigationAction[];
  contingencyActions: ContingencyAction[];
  status: 'open' | 'mitigated' | 'closed' | 'materialised';
  reviewDate: Date;
}

// Risk matrix: 5×5 grid
// Score 1–4:   Green (Low)
// Score 5–9:   Amber (Medium) — PM must review weekly
// Score 10–19: Red (High) — MD must be notified
// Score 20–25: Critical — Project Stop, immediate escalation
```

### 2.4 Change Control Process

Any change to approved contract scope:

```
Change Request raised (PM or Client)
    → EstimatingAgent assesses impact (cost + programme)
    → PM reviews AI assessment, adjusts if needed
    → Client presented with Change Order (CO)
        → Client approves → CO issued → Scope updated [Blockchain anchor]
        → Client rejects → Documented, scope unchanged
        → Client negotiates → Revision loop
```

### 2.5 Quality Management

Every project has a **Quality Plan** defining:

| Element | Description |
|---------|-------------|
| Inspection Hold Points | Mandatory sign-off before proceeding |
| Witness Points | Client/engineer may attend (optional) |
| Test Records | Required test documentation |
| Non-Conformance Reports | NCR process for defects |
| QA Checklists | Phase-specific checklists (in Nexus) |

---

## 3. Notification & Communication Framework

### 3.1 Notification Channels

```
Event occurs in Nexus
    ↓
NotificationService (NestJS)
    ↓
    ├── In-app (Supabase Realtime → UI badge + toast)
    ├── Nexus Chat (bot message to relevant channel)
    ├── Email (AWS SES — for external users/clients)
    ├── Push (FCM — for mobile app users)
    └── SMS (AWS SNS — for critical alerts only)
```

### 3.2 Notification Preference Matrix

| Notification Type | In-app | Chat | Email | Push | SMS |
|------------------|--------|------|-------|------|-----|
| Task assigned to me | ✓ | ✓ | Optional | ✓ | — |
| Task overdue | ✓ | ✓ | Daily digest | ✓ | — |
| Milestone due (48h) | ✓ | ✓ | ✓ | ✓ | — |
| Invoice issued | ✓ | ✓ | ✓ (client) | ✓ | — |
| Payment received | ✓ | ✓ | ✓ | ✓ | — |
| AI approval required | ✓ | ✓ | ✓ | ✓ | — |
| CoC issued | ✓ | ✓ | ✓ (client) | ✓ | — |
| System down (P0) | ✓ | ✓ | ✓ | ✓ | ✓ |
| SLA breach | ✓ | ✓ | ✓ | ✓ | ✓ |
| New chat @mention | ✓ | — | Optional | ✓ | — |

---

## 4. Reporting Framework

### 4.1 Standard Reports

| Report | Frequency | Audience | Delivery |
|--------|-----------|---------|---------|
| Project Status Report | Weekly | PM, Client | Email + Portal |
| Financial Summary | Monthly | MD, Finance | Dashboard + Email |
| SLA Performance | Monthly | Operations | Dashboard |
| Resource Utilisation | Weekly | PM, MD | Dashboard |
| AI Agent Performance | Weekly | Tech Lead | Dashboard |
| Compliance Calendar | Monthly | Compliance | Dashboard + Email |
| Blockchain Audit Report | Monthly | MD, Legal | Portal PDF |
| Sales & Pipeline | Weekly | BD, MD | Dashboard |

### 4.2 AI-Generated Report Pipeline

```python
# DocumentAgent generates reports automatically

report_workflow = StateGraph(ReportState)
report_workflow.add_node("gather_data", gather_data_from_supabase)
report_workflow.add_node("analyse", analyse_with_llm)
report_workflow.add_node("generate_narrative", generate_narrative)
report_workflow.add_node("format_pdf", format_to_pdf)
report_workflow.add_node("human_review", human_review_gate)  # HITL
report_workflow.add_node("distribute", distribute_report)
report_workflow.add_node("anchor_blockchain", anchor_to_polygon)
```

---

*State management and project management standards are living documents updated per retrospective findings.*
