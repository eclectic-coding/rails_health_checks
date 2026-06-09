# Roadmap

Rails 7.1 added a basic `/up` endpoint via `Rails::HealthController`, but it only verifies the app boots — no dependency checks, no pluggability, no configuration. `rails_health_checks` fills that gap as a production-grade, extensible health check engine with pluggable checks, a clean configuration DSL, and structured JSON responses that monitoring tools can consume.

---

## [0.3.0] — Cache & Queue Checks

> Cover the most common production dependencies.

**Built-in checks:**
- `good_job` — GoodJob queue latency check
- `resque` — Resque connectivity and queue depth threshold

Checks for non-installed adapters raise a descriptive error at boot, not at request time.

---

## [0.4.0] — System Checks & Result Caching

> Host-level visibility and protection against hammering dependencies on every request.

**Built-in checks:**
- `disk_space` — free disk bytes vs configurable warn/critical thresholds
- `memory` — process RSS vs configurable threshold
- `http` — arbitrary external URL with configurable expected status code

**Result caching:**
- `config.cache_ttl = 30` — cache check results for N seconds (default: off)
- Cached responses include `"cached": true` in the JSON payload
- Uses `Rails.cache` when available; falls back to an in-process store

---

## [0.5.0] — Custom Checks & Composite Groups

> First-class extensibility for host applications.

**Custom check API:**
```ruby
class MyApiCheck < RailsHealthChecks::Check
  def call
    res = Net::HTTP.get_response(URI('https://api.example.com/status'))
    res.code == '200' ? pass : fail_with("API returned #{res.code}")
  end
end

RailsHealthChecks.configure do |config|
  config.register :external_api, MyApiCheck.new
end
```

**Composite groups:**
```ruby
config.group :external_services, [:external_api, :payment_gateway]
# GET /health/external_services returns rolled-up status for the group
```

**Per-environment toggling:**
```ruby
config.disable :disk_space, in: :test
```

---

## [0.6.0] — Async & Observability

> Production performance and integration with monitoring pipelines.

- **Parallel check execution** — run checks concurrently via `Concurrent::Future` (already a Rails transitive dependency)
- **Per-check timeout** — `config.register :slow_api, check, timeout: 10`
- **ActiveSupport::Notifications** — publish `health_check.rails_health_checks` on each run; host apps can subscribe for custom alerting
- **Prometheus endpoint** — `GET /health/metrics` returning Prometheus text exposition format

---

## [1.0.0] — Stable

> Production-hardened, fully documented, and migration-friendly.

- Complete README: configuration reference, all built-in checks, custom check authoring guide
- `rails generate rails_health_checks:initializer` — generates a commented `config/initializers/rails_health_checks.rb` with all available options
- Migration guide from `okcomputer` (check name mappings)
- Rails 8.1+ compatibility locked in CI matrix
- Performance benchmarks
- CHANGELOG complete
