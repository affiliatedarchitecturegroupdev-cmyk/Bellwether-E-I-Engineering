# Accessibility Guidelines

BEIE Nexus is committed to providing an accessible experience for all users. This document outlines our accessibility standards and implementation guidelines.

## Legal Compliance

### Standards
- **WCAG 2.1 Level AA**: Primary compliance target
- **Section 508**: US government accessibility requirements
- **EN 301 549**: European accessibility standards
- **POPIA**: South African data protection (accessibility implications)

### Scope
- All public-facing websites and applications
- Internal dashboards and tools
- Mobile applications
- Documentation and support materials

## Accessibility Principles

### 1. Perceivable
Information and user interface components must be presentable to users in ways they can perceive.

#### Text Alternatives
- All images must have descriptive `alt` attributes
- Icons must have screen reader labels
- Decorative images use empty `alt=""` or `aria-hidden="true"`

#### Time-Based Media
- Videos must have captions and transcripts
- Audio content requires transcripts
- Auto-playing media must be controllable

#### Adaptable Content
- Content structure uses semantic HTML
- Color is not the only way to convey information
- Text can be resized up to 200% without loss of functionality

### 2. Operable
User interface components and navigation must be operable.

#### Keyboard Navigation
- All interactive elements accessible via keyboard
- Logical tab order (DOM order)
- Visible focus indicators on all focusable elements
- Keyboard shortcuts documented and customizable

#### Enough Time
- No time limits for user input
- Adjustable time limits where they exist
- Pause/stop/hide moving content

#### Seizure Prevention
- No content flashes more than 3 times per second
- Reduced motion respects `prefers-reduced-motion`

### 3. Understandable
Information and operation of the user interface must be understandable.

#### Readable Text
- Minimum contrast ratio of 4.5:1 for normal text
- Minimum contrast ratio of 3:1 for large text
- Text can be resized without assistive technology

#### Predictable Behavior
- Consistent navigation patterns
- Consistent interaction patterns
- Context changes only on user request

#### Input Assistance
- Clear labels and instructions
- Error messages clearly identify the problem
- Suggestions for correction provided

### 4. Robust
Content must be robust enough to be interpreted reliably by a wide variety of user agents.

#### Compatible Markup
- Valid HTML5
- ARIA specifications followed
- Semantic HTML used appropriately

#### Name, Role, Value
- Interactive elements have accessible names
- ARIA roles used appropriately
- State and property changes communicated

## Implementation Guidelines

### Frontend Components

#### Button Components
```typescript
// ✅ Accessible button
<Button
  onClick={handleClick}
  aria-label="Save project changes"
  disabled={isLoading}
>
  {isLoading ? 'Saving...' : 'Save Changes'}
</Button>

// ❌ Inaccessible button
<button onClick={handleClick} style={{ opacity: 0.5 }}>
  Save
</button>
```

#### Form Fields
```typescript
// ✅ Accessible form field
<div>
  <label htmlFor="projectName" className="required">
    Project Name
  </label>
  <input
    id="projectName"
    type="text"
    value={projectName}
    onChange={handleChange}
    aria-describedby="projectNameHelp"
    aria-invalid={!!error}
    required
  />
  <div id="projectNameHelp" className="help-text">
    Enter a descriptive name for your project
  </div>
  {error && (
    <div role="alert" className="error-message">
      {error}
    </div>
  )}
</div>
```

#### Modal/Dialog
```typescript
// ✅ Accessible modal
<Modal
  isOpen={isOpen}
  onClose={handleClose}
  title="Confirm Project Deletion"
  description="This action cannot be undone"
>
  <ModalContent>
    Are you sure you want to delete this project?
  </ModalContent>
  <ModalActions>
    <Button onClick={handleClose}>Cancel</Button>
    <Button variant="danger" onClick={handleDelete}>
      Delete Project
    </Button>
  </ModalActions>
</Modal>
```

### Data Tables

#### Accessible Table Structure
```typescript
// ✅ Accessible data table
<table role="table" aria-label="Project list">
  <thead>
    <tr>
      <th scope="col" aria-sort="none">Project Name</th>
      <th scope="col" aria-sort="ascending">Status</th>
      <th scope="col" aria-sort="none">Due Date</th>
      <th scope="col">Actions</th>
    </tr>
  </thead>
  <tbody>
    {projects.map(project => (
      <tr key={project.id}>
        <th scope="row">{project.name}</th>
        <td>
          <Badge status={project.status}>
            {project.status}
          </Badge>
        </td>
        <td>{formatDate(project.dueDate)}</td>
        <td>
          <Button
            size="sm"
            aria-label={`Edit ${project.name}`}
            onClick={() => handleEdit(project)}
          >
            Edit
          </Button>
        </td>
      </tr>
    ))}
  </tbody>
</table>
```

### Color and Contrast

#### Color Palette Compliance
```css
:root {
  /* Primary colors with high contrast */
  --color-primary: #2D6A4F;        /* WCAG AA compliant */
  --color-primary-text: #FFFFFF;   /* 15.8:1 contrast */

  --color-secondary: #74C69D;      /* WCAG AA compliant */
  --color-secondary-text: #0A0A0A; /* 4.6:1 contrast */

  /* Semantic colors */
  --color-success: #2D6A4F;        /* Green */
  --color-warning: #D4A017;        /* Yellow */
  --color-error: #C1121F;          /* Red */
  --color-info: #1B2A4A;           /* Blue */

  /* Neutral colors */
  --color-text-primary: #0A0A0A;   /* Black */
  --color-text-secondary: rgba(10, 10, 10, 0.65);
  --color-text-tertiary: rgba(10, 10, 10, 0.40);
  --color-border: rgba(10, 10, 10, 0.12);
}
```

#### Dark Mode Support
```css
[data-theme="dark"] {
  --color-text-primary: #F5F4F0;   /* Light */
  --color-text-secondary: rgba(245, 244, 240, 0.65);
  --color-text-tertiary: rgba(245, 244, 240, 0.40);
  --color-border: rgba(245, 244, 240, 0.12);
}
```

### Keyboard Navigation

#### Focus Management
```typescript
// ✅ Proper focus management
const Modal = ({ isOpen, onClose, children }) => {
  const modalRef = useRef(null);
  const previousFocusRef = useRef(null);

  useEffect(() => {
    if (isOpen) {
      previousFocusRef.current = document.activeElement;
      modalRef.current?.focus();
    } else {
      previousFocusRef.current?.focus();
    }
  }, [isOpen]);

  return (
    <div
      ref={modalRef}
      tabIndex={-1}
      role="dialog"
      aria-modal="true"
      aria-labelledby="modal-title"
    >
      {children}
    </div>
  );
};
```

#### Keyboard Shortcuts
```typescript
// ✅ Accessible keyboard shortcuts
const useKeyboardShortcuts = () => {
  useEffect(() => {
    const handleKeyDown = (event) => {
      // Only trigger if no input/textarea is focused
      if (event.target.tagName === 'INPUT' ||
          event.target.tagName === 'TEXTAREA' ||
          event.target.contentEditable === 'true') {
        return;
      }

      switch (event.key) {
        case 's':
          if (event.ctrlKey || event.metaKey) {
            event.preventDefault();
            handleSave();
          }
          break;
        case 'n':
          if (event.ctrlKey || event.metaKey) {
            event.preventDefault();
            handleNew();
          }
          break;
        case '/':
          event.preventDefault();
          showKeyboardShortcuts();
          break;
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, []);
};
```

### Screen Reader Support

#### ARIA Labels and Descriptions
```typescript
// ✅ Proper ARIA usage
<div
  role="progressbar"
  aria-valuenow={progress}
  aria-valuemin={0}
  aria-valuemax={100}
  aria-label="Project completion progress"
>
  <div style={{ width: `${progress}%` }} />
</div>

// ✅ Live regions for dynamic content
<div aria-live="polite" aria-atomic="true">
  {notification && (
    <div role="alert">
      {notification.message}
    </div>
  )}
</div>
```

### Testing and Validation

#### Automated Testing
- **axe-core**: Automated accessibility testing
- **Lighthouse**: Accessibility audits
- **WAVE**: Web accessibility evaluation
- **Accessibility Insights**: Microsoft accessibility tools

#### Manual Testing Checklist
- [ ] Keyboard navigation works
- [ ] Screen reader announces content correctly
- [ ] Color contrast meets WCAG standards
- [ ] Focus indicators are visible
- [ ] Form validation messages are accessible
- [ ] Page can be navigated with screen reader
- [ ] All images have appropriate alt text
- [ ] Headings follow logical hierarchy
- [ ] Links have descriptive text

#### Screen Reader Testing
- **NVDA** (Windows) or **VoiceOver** (macOS)
- **JAWS** (Windows) or **Orca** (Linux)
- Mobile screen readers: TalkBack (Android), VoiceOver (iOS)

### Documentation and Training

#### Developer Guidelines
- Accessibility considerations in PR templates
- Code review checklist includes accessibility
- Regular training sessions on accessibility best practices

#### User Documentation
- Keyboard shortcuts documented
- Screen reader instructions provided
- Alternative access methods explained

### Monitoring and Maintenance

#### Continuous Monitoring
- Automated accessibility tests in CI/CD
- Regular manual accessibility audits
- User feedback collection and analysis

#### Issue Tracking
- Accessibility issues labeled and prioritized
- Regular review of accessibility backlog
- Progress tracking against WCAG compliance

### Tools and Resources

#### Development Tools
- **Storybook**: Component accessibility testing
- **Browser DevTools**: Accessibility tab
- **Color Contrast Analyzers**: Contrast ratio checking
- **Accessibility Linters**: ESLint accessibility plugins

#### Browser Extensions
- **axe DevTools**: Automated testing
- **WAVE Evaluation Tool**: Manual evaluation
- **Accessibility Insights**: Comprehensive assessment

#### Learning Resources
- **WCAG Guidelines**: https://www.w3.org/WAI/WCAG21/quickref/
- **ARIA Practices**: https://www.w3.org/WAI/ARIA/apg/
- **Deque University**: https://dequeuniversity.com/
- **WebAIM**: https://webaim.org/

## Accessibility Statement

BEIE Nexus is committed to ensuring digital accessibility for people with disabilities. We are continually improving the user experience for everyone and applying the relevant accessibility standards.

If you encounter any accessibility barriers on our website or in our applications, please contact us at accessibility@beie.co.za. We will work to address the issue promptly.

This accessibility guidelines document ensures BEIE Nexus provides an inclusive experience for all users, regardless of ability.