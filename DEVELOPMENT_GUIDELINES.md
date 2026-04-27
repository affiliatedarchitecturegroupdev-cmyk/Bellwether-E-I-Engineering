# BEIE Nexus Development Guidelines

These directives must be followed for every step of the 200-phase development roadmap.

## Phase Management

### Phase Manifest File
- Single PHASES.md tracks status of each phase (not started / in progress / done / blocked)
- Update PHASES.md immediately after completing each phase
- Include LoC count per phase and cumulative project LoC

### One Phase = One PR
- Create dedicated git branch per phase: `phase/X-description`
- Implement all changes for that phase in the branch
- Create GitHub PR for review and merge to main
- Never commit directly to main except for urgent hotfixes

### Shared Architecture Documentation
- Maintain 01_SYSTEM_ARCHITECTURE.md as single source of truth
- Update architecture docs with each phase completion
- Agents must reference these docs to avoid conflicting assumptions

### Test Suite Per Phase
- Include unit, integration, and E2E tests for every phase
- Run full test suite before PR creation
- Security and performance tests where applicable

## Git Branching Strategy

```
main (production-ready)
├── phase/1-aws-account-setup
├── phase/2-terraform-foundation
├── phase/16-nestjs-api-gateway (completed)
├── phase/17-authentication-service-core (completed)
└── phase/18-multi-tenant-middleware (current)
```

## LoC Tracking

- Use `git diff --stat` to count lines added/removed per phase
- Update PHASES.md with exact LoC numbers
- Cumulative LoC = sum of all completed phases

## Quality Gates

- TypeScript strict mode enforced
- ESLint rules must pass
- Test coverage minimum 70% for new code
- Security scan (Snyk) must pass
- Performance budgets must not be exceeded

## Communication

- All changes must be reviewable in PR description
- Include "What changed" and "Why" in commit messages
- Update relevant documentation with each phase

## Emergency Procedures

- If phase blocks development, mark as blocked in PHASES.md
- Create separate branch for hotfixes: `hotfix/description`
- Hotfixes can be merged directly with senior approval