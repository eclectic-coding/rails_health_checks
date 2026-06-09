# Roadmap

Rails 7.1 added a basic `/up` endpoint via `Rails::HealthController`, but it only verifies the app boots — no dependency checks, no pluggability, no configuration. `rails_health_checks` fills that gap as a production-grade, extensible health check engine with pluggable checks, a clean configuration DSL, and structured JSON responses that monitoring tools can consume.

---

## [1.0.0] — Stable

> Production-hardened, fully documented, and migration-friendly.

- Complete README: configuration reference, all built-in checks, custom check authoring guide
- `rails generate rails_health_checks:initializer` — generates a commented `config/initializers/rails_health_checks.rb` with all available options
- Migration guide from `okcomputer` (check name mappings)
- Rails 8.1+ compatibility locked in CI matrix
- Performance benchmarks
- CHANGELOG complete
