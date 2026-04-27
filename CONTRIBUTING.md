# Contributing to BEIE Nexus

Thank you for your interest in contributing to BEIE Nexus! This document outlines the process for contributing to our project.

## Code of Conduct

Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## Development Process

### 1. Choose a Phase
- Check [PHASES.md](PHASES.md) for current status
- Pick an available phase or create an issue for new features
- Follow the 200-phase roadmap in [ROADMAP-002.md](ROADMAP-002.md)

### 2. Development Workflow
1. **Fork** the repository
2. **Create a branch** from `main`: `git checkout -b phase/X-description`
3. **Implement** your changes following [DEVELOPMENT_GUIDELINES.md](DEVELOPMENT_GUIDELINES.md)
4. **Test** thoroughly (unit, integration, E2E)
5. **Commit** with conventional commits: `feat: add new feature`
6. **Push** your branch: `git push origin phase/X-description`
7. **Create a Pull Request** using the PR template

### 3. Pull Request Process
- Fill out the PR template completely
- Ensure CI checks pass
- Request review from maintainers
- Address review feedback
- PRs are squashed and merged to `main`

## Commit Guidelines

Follow [Conventional Commits](https://conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `security`

Scopes: `web-public`, `api-gateway`, `ui`, `ai`, `blockchain`, etc.

Examples:
- `feat(api): add user authentication`
- `fix(ui): resolve button hover state`
- `docs: update API reference`

## Code Quality Standards

- **TypeScript**: Strict mode, no `any`, proper typing
- **Testing**: Minimum 70% coverage, both unit and integration
- **Linting**: ESLint must pass
- **Security**: Snyk scans must pass
- **Performance**: Meet budgets in [docs/PERFORMANCE.md](docs/PERFORMANCE.md)

## Testing Requirements

- Unit tests for all new functions
- Integration tests for API endpoints
- E2E tests for critical user flows
- Accessibility tests (WCAG 2.1 AA)
- Performance tests

## Documentation

- Update relevant docs for any changes
- Add JSDoc/TypeScript comments for public APIs
- Update [docs/API_REFERENCE.md](docs/API_REFERENCE.md) for API changes

## Getting Help

- Check existing issues and documentation first
- Create an issue for bugs or feature requests
- Join our Discord/Slack for questions

## Recognition

Contributors are recognized in:
- GitHub contributor stats
- Release notes
- BEIE Nexus website (if applicable)

Thank you for contributing to BEIE Nexus! 🎉