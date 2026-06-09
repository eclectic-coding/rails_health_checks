# Roadmap

Rails 7.1 added a basic `/up` endpoint via `Rails::HealthController`, but it only verifies the app boots — no dependency checks, no pluggability, no configuration. `rails_health_checks` fills that gap as a production-grade, extensible health check engine with pluggable checks, a clean configuration DSL, and structured JSON responses that monitoring tools can consume.

---

## [0.7.0] — Production Polish

> Small features that close real production pain points before 1.0.0.

- **Result caching** — `config.cache_duration = N` (seconds) avoids re-running expensive checks on every request; default off; keyed per check set so groups cache independently
- **HEAD request support** — verify and document HEAD on `GET /health` and `GET /health/live` for load balancer compatibility
- **HTTP check custom headers** — `config.http_headers = { "Authorization" => "Bearer ..." }` enables probing authenticated endpoints
- **Boot-time config validation** — raises `ConfigurationError` at startup for unknown check names, `:http` with no `http_url`, and groups referencing missing checks

---

## [1.0.0] — Stable

> Production-hardened, fully documented, and migration-friendly.

- Complete README: configuration reference, all built-in checks, custom check authoring guide
- `rails generate rails_health_checks:initializer` — generates a commented `config/initializers/rails_health_checks.rb` with all available options
- Migration guide from `okcomputer` (check name mappings)
- Rails 8.1+ compatibility locked in CI matrix
- Performance benchmarks
- CHANGELOG complete
