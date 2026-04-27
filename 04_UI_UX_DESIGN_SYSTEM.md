# BEIE Nexus — UI/UX Design System & Device Guidelines
**Document:** UI-001 | **Version:** 1.0.0 | **Status:** Canonical  
**Applies To:** All BEIE Nexus frontend surfaces

---

## 1. Design Philosophy

### 1.1 Core Principles

| Principle | Definition |
|-----------|------------|
| **Precision Over Decoration** | Every visual element earns its place. No ornamentation without function. |
| **Institutional Confidence** | The UI must feel as credible as a Bloomberg terminal — engineered, not styled. |
| **Adaptive Density** | Information density scales to device and user role. A CEO sees summaries; an engineer sees raw data. |
| **Progressive Disclosure** | Complex features reveal themselves as users need them. No overwhelming onboarding. |
| **Motion with Intent** | Animations communicate state changes, not personality. Every animation has a semantic purpose. |

### 1.2 Anti-Patterns (Explicitly Banned)

- No purple gradient on white backgrounds
- No generic San Francisco / Inter / Roboto as the primary display font
- No card carousels on desktop (use tables or grids)
- No hamburger menus on desktop resolutions
- No modal-on-modal stacking
- No loading spinners without progress indication for operations > 3 seconds
- No dark patterns in the e-commerce funnel

---

## 2. Design Tokens

### 2.1 Colour System

```css
:root {
  /* Primary Palette */
  --color-black:       #0A0A0A;
  --color-white:       #F5F4F0;
  --color-green-900:   #1B4332;
  --color-green-700:   #2D6A4F;  /* Primary brand green */
  --color-green-500:   #52B788;  /* Interactive green */
  --color-green-300:   #74C69D;  /* Accent / highlight */
  --color-green-100:   #D8F3DC;  /* Pale / background tint */
  --color-navy-900:    #0D1B2A;
  --color-navy-700:    #1B2A4A;  /* Primary navy */
  --color-navy-500:    #2C3E6B;  /* Mid navy */
  --color-navy-300:    #4A5E8A;  /* Light navy */

  /* Semantic Colours */
  --color-success:     #2D6A4F;
  --color-warning:     #D4A017;
  --color-error:       #C1121F;
  --color-info:        #1B2A4A;

  /* Surface Hierarchy */
  --surface-base:      #0A0A0A;
  --surface-raised:    #141414;
  --surface-overlay:   #1E1E1E;
  --surface-floating:  #252525;

  /* Border */
  --border-subtle:     rgba(245,244,240,0.06);
  --border-default:    rgba(245,244,240,0.12);
  --border-strong:     rgba(245,244,240,0.24);
  --border-brand:      rgba(82,183,136,0.4);

  /* Text */
  --text-primary:      #F5F4F0;
  --text-secondary:    rgba(245,244,240,0.65);
  --text-tertiary:     rgba(245,244,240,0.40);
  --text-brand:        #74C69D;
  --text-disabled:     rgba(245,244,240,0.25);
}

/* Light Mode (Client Portal) */
[data-theme="light"] {
  --surface-base:      #F5F4F0;
  --surface-raised:    #FFFFFF;
  --surface-overlay:   #F0EFE8;
  --text-primary:      #0A0A0A;
  --text-secondary:    rgba(10,10,10,0.65);
  --color-green-700:   #2D6A4F;
  --border-subtle:     rgba(10,10,10,0.06);
}
```

### 2.2 Typography

```css
/* Font Stack */
--font-display:   'Bebas Neue', sans-serif;     /* Headlines, metrics, numbers */
--font-body:      'DM Sans', sans-serif;        /* All body copy, UI labels */
--font-mono:      'DM Mono', monospace;         /* Code, IDs, technical data */
--font-data:      'Tabular', 'DM Mono', mono;  /* Tables, financial data */

/* Type Scale (fluid) */
--text-xs:    clamp(0.625rem, 0.6rem + 0.125vw, 0.75rem);   /* 10–12px */
--text-sm:    clamp(0.75rem, 0.7rem + 0.25vw, 0.875rem);    /* 12–14px */
--text-base:  clamp(0.875rem, 0.8rem + 0.375vw, 1rem);      /* 14–16px */
--text-md:    clamp(1rem, 0.9rem + 0.5vw, 1.125rem);        /* 16–18px */
--text-lg:    clamp(1.125rem, 1rem + 0.625vw, 1.375rem);    /* 18–22px */
--text-xl:    clamp(1.375rem, 1.2rem + 0.875vw, 1.75rem);   /* 22–28px */
--text-2xl:   clamp(1.75rem, 1.5rem + 1.25vw, 2.5rem);     /* 28–40px */
--text-3xl:   clamp(2.5rem, 2rem + 2.5vw, 4rem);           /* 40–64px */
--text-4xl:   clamp(4rem, 3rem + 5vw, 7rem);               /* 64–112px */

/* Line Heights */
--leading-tight:   0.95;   /* Display headlines */
--leading-snug:    1.25;   /* Subheadings */
--leading-normal:  1.5;    /* UI labels */
--leading-relaxed: 1.7;    /* Body copy */
--leading-loose:   2.0;    /* Accessibility mode */

/* Letter Spacing */
--tracking-tight:  -0.02em;
--tracking-normal:  0;
--tracking-wide:    0.06em;
--tracking-wider:   0.12em;
--tracking-widest:  0.2em;  /* All-caps labels */
```

### 2.3 Spacing System

```css
/* Base unit: 4px */
--space-1:  0.25rem;  /* 4px  */
--space-2:  0.5rem;   /* 8px  */
--space-3:  0.75rem;  /* 12px */
--space-4:  1rem;     /* 16px */
--space-5:  1.25rem;  /* 20px */
--space-6:  1.5rem;   /* 24px */
--space-8:  2rem;     /* 32px */
--space-10: 2.5rem;   /* 40px */
--space-12: 3rem;     /* 48px */
--space-16: 4rem;     /* 64px */
--space-20: 5rem;     /* 80px */
--space-24: 6rem;     /* 96px */
--space-32: 8rem;     /* 128px */
```

### 2.4 Motion & Animation

```css
/* Duration */
--duration-instant:  50ms;
--duration-fast:    150ms;
--duration-normal:  300ms;
--duration-slow:    500ms;
--duration-slower:  800ms;

/* Easing */
--ease-out:      cubic-bezier(0.0, 0.0, 0.2, 1.0);   /* Elements entering */
--ease-in:       cubic-bezier(0.4, 0.0, 1.0, 1.0);   /* Elements leaving */
--ease-in-out:   cubic-bezier(0.4, 0.0, 0.2, 1.0);   /* State transitions */
--ease-spring:   cubic-bezier(0.175, 0.885, 0.32, 1.275); /* Bouncy/delight */

/* Reduce motion */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

### 2.5 Elevation & Shadow

```css
--shadow-sm:  0 1px 2px rgba(0,0,0,0.4);
--shadow-md:  0 4px 12px rgba(0,0,0,0.5);
--shadow-lg:  0 8px 32px rgba(0,0,0,0.6);
--shadow-xl:  0 20px 60px rgba(0,0,0,0.7);
--shadow-brand: 0 0 24px rgba(82,183,136,0.2);
--shadow-glow:  0 0 40px rgba(82,183,136,0.15);
```

---

## 3. Device Breakpoint System

### 3.1 Breakpoint Definitions

```typescript
export const breakpoints = {
  // Micro devices
  watch:         '240px',   // Smart watches (future)
  
  // Mobile
  mobileXS:      '320px',   // Small Android phones
  mobileSM:      '375px',   // iPhone SE
  mobileMD:      '390px',   // iPhone 14/15
  mobileLG:      '428px',   // iPhone Plus/Max
  
  // Tablet
  tabletSM:      '600px',   // Small tablets, large phones landscape
  tabletMD:      '768px',   // iPad portrait
  tabletLG:      '1024px',  // iPad landscape / iPad Pro portrait
  
  // Desktop
  desktopSM:     '1280px',  // Small laptop (13")
  desktopMD:     '1440px',  // Standard desktop (24" FHD)
  desktopLG:     '1680px',  // Large desktop (27" QHD)
  desktopXL:     '1920px',  // Full HD
  
  // Ultra-wide & TV
  ultrawide:     '2560px',  // 4K, ultrawide monitors
  tv:            '3840px',  // 4K TV
} as const;
```

### 3.2 Responsive Behaviour by Surface

#### Corporate Website (Next.js)

| Breakpoint | Layout | Navigation | Typography Scale |
|------------|--------|-----------|-----------------|
| < 768px | Single column, stacked | Hamburger overlay | 75% |
| 768–1024px | 2-column where applicable | Collapsed with icons | 87.5% |
| 1024–1440px | Full layout | Full horizontal nav | 100% |
| > 1440px | Capped max-width: 1440px, centred | Full nav | 100% |
| TV | Capped max-width: 1920px, large fonts | Full nav, overscan-safe | 150% |

#### Dashboard / ERP (Angular)

| Breakpoint | Layout | Sidebar | Content |
|------------|--------|---------|---------|
| < 768px | Mobile-first, bottom nav | Hidden, drawer | Full width |
| 768–1024px | Tablet, collapsible sidebar | Icon-only (collapsed) | Full width |
| 1024–1440px | Standard dashboard | 240px expanded | Remaining width |
| > 1440px | Wide dashboard | 280px expanded | Remaining width |
| TV | Kiosk/display mode | Hidden | Full screen dashboard |

#### TV / Display Mode Rules

- Minimum touch/click target: 80×80px (standard: 44×44px)
- Font size minimum: 24px for readable text at 3m distance
- High contrast mode: automatically enabled
- Overscan safe zones: 5% margin on all sides
- Auto-refresh: dashboards refresh every 60 seconds
- Cursor hidden in kiosk mode
- No modals or overlays in TV mode (no way to dismiss)

---

## 4. Component Standards

### 4.1 Core Component Inventory

```
Components/
├── Foundations/
│   ├── Button (primary, secondary, ghost, danger, icon)
│   ├── Input (text, number, date, search, password)
│   ├── Select (single, multi, combobox)
│   ├── Checkbox, Radio, Toggle
│   ├── Badge, Tag, Chip
│   ├── Avatar (user, company, placeholder)
│   └── Divider
├── Layout/
│   ├── Page (with header, sidebar, content, footer slots)
│   ├── Section (with padding, max-width, background variants)
│   ├── Grid (1–12 column, responsive)
│   ├── Stack (vertical/horizontal, gap, alignment)
│   ├── Card (flat, raised, interactive, stat)
│   └── Sidebar (collapsible, icon-mode, mobile drawer)
├── Navigation/
│   ├── Topbar (logo, search, actions, user menu)
│   ├── Sidebar Nav (items, groups, badges, active state)
│   ├── Breadcrumb
│   ├── Tabs (underline, pill, card)
│   ├── Pagination
│   └── Stepper (linear, non-linear)
├── Data Display/
│   ├── Table (sortable, filterable, selectable, virtual scroll)
│   ├── DataGrid (for ERP heavy data)
│   ├── KanbanBoard
│   ├── GanttChart
│   ├── Timeline
│   ├── Stat (number, trend, sparkline)
│   ├── Chart (line, bar, area, donut — D3 wrapper)
│   └── Map (Leaflet, project site pins)
├── Feedback/
│   ├── Alert (info, success, warning, error)
│   ├── Toast / Notification
│   ├── Modal (standard, fullscreen, drawer)
│   ├── Confirm Dialog
│   ├── Skeleton Loader
│   └── ProgressBar / Stepper
├── Forms/
│   ├── FormField (label, input, hint, error)
│   ├── FormSection
│   ├── FormWizard (multi-step)
│   ├── FileUpload (drag-drop, multi, progress)
│   ├── RichTextEditor
│   └── SignaturePad (for digital approvals)
├── AI/
│   ├── AgentChat (conversational interface)
│   ├── HumanApprovalCard (approve/reject AI proposals)
│   ├── ConfidenceBadge (show AI confidence score)
│   ├── SuggestionList (AI recommendations)
│   └── AIStatusIndicator (thinking, complete, error)
└── Domain-Specific/
    ├── ProjectCard
    ├── TaskRow
    ├── InvoiceCard
    ├── ProductCard (e-commerce)
    ├── ChatMessage
    ├── BlockchainVerification (show on-chain record)
    └── ComplianceStatus
```

### 4.2 Component Accessibility Standards

Every component MUST:
- Have `role` and `aria-label` where semantic HTML is insufficient
- Support keyboard navigation (Tab, Shift+Tab, Enter, Space, Escape, Arrow keys)
- Meet WCAG 2.1 AA contrast ratios (4.5:1 text, 3:1 UI components)
- Have a focus ring visible against all backgrounds
- Support `prefers-reduced-motion`
- Support `prefers-color-scheme` (light/dark)
- Have screen reader announcements for dynamic state changes

### 4.3 Component API Standards (Angular)

```typescript
// All components must export:
@Component({
  selector: 'nx-[component-name]',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush, // Always OnPush
})
export class NxComponent {
  // Inputs: typed, with defaults
  @Input() variant: 'primary' | 'secondary' = 'primary';
  @Input() size: 'sm' | 'md' | 'lg' = 'md';
  @Input() disabled = false;
  @Input() loading = false;
  @Input() ariaLabel: string = '';
  
  // Outputs: EventEmitter with typed payload
  @Output() action = new EventEmitter<ActionPayload>();
  
  // Host bindings for a11y
  @HostBinding('attr.role') role = 'button';
}
```

---

## 5. Layout System

### 5.1 Dashboard Layout (Angular)

```
┌──────────────────────────────────────────────────────────┐
│  TOPBAR: Logo · Search · Notifications · User Menu       │  64px fixed
├─────────┬────────────────────────────────────────────────┤
│ SIDEBAR │                                                │
│ 240px   │  CONTENT AREA                                 │
│         │  Max-width: none (fills remaining)            │
│  Nav    │                                                │
│  Groups │  ┌──────────────────────────────────────────┐ │
│  ·      │  │ PAGE HEADER (title, breadcrumb, actions) │ │  80px
│  ·      │  ├──────────────────────────────────────────┤ │
│  ·      │  │                                          │ │
│  ·      │  │  PAGE BODY (scrollable)                  │ │
│         │  │                                          │ │
│  User   │  └──────────────────────────────────────────┘ │
└─────────┴────────────────────────────────────────────────┘
```

### 5.2 Content Width Constraints

| Context | Max Width | Padding |
|---------|----------|---------|
| Public website | 1440px | 4rem (desktop), 1.5rem (mobile) |
| Dashboard content | Unlimited | 2rem (desktop), 1rem (mobile) |
| Article / documentation | 780px | Inherited |
| Modal content | 560px (sm), 780px (md), 1000px (lg) | 2rem |
| Form content | 560px | Inherited |

### 5.3 Grid Standards

- 12-column grid on desktop
- 4-column grid on tablet
- 1–2 column grid on mobile
- Gutters: 24px desktop, 16px tablet, 12px mobile
- Never break the grid with absolutely positioned elements in content areas

---

## 6. E-Commerce UI Standards

### 6.1 Product Catalogue

- Product cards: 3 columns (desktop), 2 (tablet), 1 (mobile)
- Card must show: image, category, product name, SKU, price (ex VAT + inc VAT), stock status, add to cart
- Search: always visible, debounced 300ms, minimum 2 characters
- Filters: left sidebar (desktop), bottom sheet (mobile)
- Image: 4:3 ratio, lazy loaded, webp with JPEG fallback, 3 views minimum per product

### 6.2 Checkout Flow

- Maximum 3 steps: Cart → Delivery/Billing → Payment
- Progress indicator always visible
- Never remove cart contents without confirmation
- Order summary persistent on right (desktop) or top (mobile)
- Payment page: PCI DSS compliant iFrame (Peach Payments hosted fields)

---

## 7. Performance Budgets

| Metric | Target | Limit |
|--------|--------|-------|
| Largest Contentful Paint (LCP) | < 2.0s | < 2.5s |
| First Input Delay (FID) | < 50ms | < 100ms |
| Cumulative Layout Shift (CLS) | < 0.05 | < 0.1 |
| Time to First Byte (TTFB) | < 400ms | < 800ms |
| Total JS bundle (public site) | < 200KB | < 350KB |
| Total JS bundle (dashboard) | < 500KB | < 800KB |
| Image weight per page | < 500KB | < 1MB |
| API response (95th percentile) | < 200ms | < 500ms |

### Performance Rules

- All images served as WebP, sized to display resolution
- Next.js Image component mandatory for all images on public site
- Angular: lazy load all non-critical modules
- Fonts: preload display fonts, font-display: swap
- Third-party scripts: never block main thread
- Service Worker: cache static assets for offline support

---

## 8. Internationalisation & Localisation

- Primary language: English (South African)
- Currency: ZAR (South African Rand) — always display as "R" prefix
- Date format: DD MMM YYYY (e.g., 25 Apr 2026)
- Time: 24-hour format
- Number format: space as thousands separator (R 1 250 000)
- All strings externalised to i18n JSON files from day one
- Right-to-left support: architected but not required Phase 1

---

## 9. Dark / Light Mode Strategy

- Default: Dark mode (brand-appropriate, engineering aesthetic)
- Client portal: Light mode default (approachable for non-technical clients)
- Toggle: available per user, stored in preferences
- System preference respected on first visit
- No flash of unstyled content (FOUC): theme applied server-side

---

*This document is the single source of truth for all BEIE Nexus visual and interaction standards.*
