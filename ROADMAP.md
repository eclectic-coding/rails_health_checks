# Roadmap

Rails 7.1 added a basic `/up` endpoint via `Rails::HealthController`, but it only verifies the app boots — no dependency checks, no pluggability, no configuration. `rails_health_checks` fills that gap as a production-grade, extensible health check engine with pluggable checks, a clean configuration DSL, and structured JSON responses that monitoring tools can consume.

---

## [0.8.0] — Extended Check Suite

> Additional built-in checks for common production dependencies.

- **SMTP check** — `config.checks = [:smtp]` verifies mail server connectivity via `Net::SMTP`; optional `config.smtp_address` and `config.smtp_port`; no extra gems required

---

## [1.0.0] — Stable

> Production-hardened, fully documented, and migration-friendly.

- Complete README: configuration reference, all built-in checks, custom check authoring guide
- Migration guide from `okcomputer` (check name mappings)
- Rails 8.1+ compatibility locked in CI matrix
- Performance benchmarks
- CHANGELOG complete
