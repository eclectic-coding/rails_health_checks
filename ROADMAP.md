# Roadmap

Rails 7.1 added a basic `/up` endpoint via `Rails::HealthController`, but it only verifies the app boots — no dependency checks, no pluggability, no configuration. `rails_health_checks` fills that gap as a production-grade, extensible health check engine with pluggable checks, a clean configuration DSL, and structured JSON responses that monitoring tools can consume.

---

## [0.1.0] — Foundation

> Initial release. Engine boots, one working endpoint, one built-in check, full specs.

**Endpoints:**
- `GET /health` — JSON response, `200 OK` (healthy) or `503 Service Unavailable` (unhealthy)
- `GET /health/live` — plain text `OK` / `Service Unavailable` for load balancer liveness probes

**Built-in checks:**
- `database` — ActiveRecord `SELECT 1` connectivity against the primary connection, includes latency

**Response shape:**
```json
{
  "status": "ok",
  "timestamp": "2026-06-08T20:00:00Z",
  "checks": {
    "database": { "status": "ok", "latency_ms": 4 }
  }
}
```
Status values: `ok` | `degraded` | `critical`. Overall is `critical` if any check is `critical`; `degraded` if any is `degraded`.

**Configuration DSL:**
```ruby
RailsHealthChecks.configure do |config|
  config.checks  = [:database]  # enable/disable built-in checks
  config.timeout = 5            # global check timeout in seconds
end
```

---

## [0.2.0] — Authentication & Authorization

> Protect health endpoints from public exposure.

- **IP allowlist** — `config.allowed_ips = ['127.0.0.1', '10.0.0.0/8']`
- **Bearer token** — `config.token = ENV['HEALTH_TOKEN']` (via `Authorization: Bearer <token>` header)
- **Custom block** — `config.authenticate { |request| request.ip == '...' }`
- Unauthenticated requests return `401 Unauthorized`

---

## [0.3.0] — Cache & Queue Checks

> Cover the most common production dependencies.

**Built-in checks:**
- `cache` — reads/writes via `Rails.cache`; works with Redis, Memcached, or in-process store
- `sidekiq` — Sidekiq connectivity and configurable queue depth threshold
- `solid_queue` — Solid Queue connectivity and pending job count
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
- Migration guide from `okcomputer` (check name mappings)
- Rails 8.1+ compatibility locked in CI matrix
- Performance benchmarks
- CHANGELOG complete
