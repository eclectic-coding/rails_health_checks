# Roadmap

Rails 7.1 added a basic `/up` endpoint via `Rails::HealthController`, but it only verifies the app boots — no dependency checks, no pluggability, no configuration. `rails_health_checks` fills that gap as a production-grade, extensible health check engine with pluggable checks, a clean configuration DSL, and structured JSON responses that monitoring tools can consume.

---

## [1.0.0] — Stable

> Production-hardened, fully documented, and migration-friendly.

- Rails 8.0+ compatibility locked in CI matrix
- Performance benchmarks
- CHANGELOG complete
