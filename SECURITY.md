# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

**Email:** security@bugstack.dev

Please do **not** open a public GitHub issue for security vulnerabilities.

We will respond within 48 hours.

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.x     | Yes       |

## Security Design

- Zero runtime gem dependencies — only Ruby stdlib
- No cookies, IP addresses, headers, or user data captured by default
- `before_send` hook lets you filter every event before it leaves your app
- `dry_run` mode for full transparency
- The SDK never raises — all errors are caught internally
- All data transmission uses HTTPS
