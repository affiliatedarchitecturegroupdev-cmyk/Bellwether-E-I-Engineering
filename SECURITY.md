# Security Policy

## Supported Versions

We actively support the following versions with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in BEIE Nexus, please help us by reporting it responsibly.

### How to Report

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please report security vulnerabilities by emailing security@beie.co.za.

Include the following information:
- A clear description of the vulnerability
- Steps to reproduce the issue
- Potential impact and severity
- Any suggested fixes or mitigations

### What to Expect

- **Acknowledgment**: We will acknowledge receipt of your report within 24 hours
- **Investigation**: We will investigate the issue and provide regular updates (at least weekly)
- **Resolution**: We will work to resolve the issue as quickly as possible
- **Disclosure**: Once resolved, we will coordinate disclosure with you

We follow responsible disclosure practices and will give credit to reporters (if desired) when we publicly disclose the vulnerability.

## Security Best Practices for Contributors

When contributing to BEIE Nexus:

### Code Security
- Never commit secrets, API keys, or credentials
- Use environment variables for configuration
- Implement proper input validation and sanitization
- Follow the principle of least privilege
- Use parameterized queries to prevent SQL injection

### Dependency Security
- Keep dependencies updated
- Use tools like Snyk or Dependabot for vulnerability scanning
- Review dependency changes in PRs
- Avoid introducing new dependencies without security review

### Authentication & Authorization
- Use established authentication libraries
- Implement proper session management
- Never store passwords in plain text
- Use multi-factor authentication where appropriate

### Data Protection
- Encrypt sensitive data at rest and in transit
- Implement proper access controls
- Follow data minimization principles
- Comply with relevant regulations (POPIA, GDPR, etc.)

### Infrastructure Security
- Use HTTPS everywhere
- Implement proper firewall rules
- Regular security audits and penetration testing
- Keep infrastructure components updated

## Security Tools & Scans

We use the following tools for security:

- **SAST**: SonarQube, ESLint security rules
- **DAST**: OWASP ZAP
- **Dependency scanning**: Snyk, Dependabot
- **Container scanning**: Trivy
- **Secret scanning**: Gitleaks, GitHub secret scanning

## Contact

For security-related questions or concerns, contact:
- Email: security@beie.co.za
- Response time: Within 24 hours for vulnerability reports