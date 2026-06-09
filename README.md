# RailsHealthChecks

[![CI](https://github.com/eclectic-coding/rails_health_checks/actions/workflows/ci.yml/badge.svg)](https://github.com/eclectic-coding/rails_health_checks/actions/workflows/ci.yml)
[![gem](https://img.shields.io/gem/v/rails_health_checks.svg)](https://rubygems.org/gems/rails_health_checks)
[![downloads](https://img.shields.io/gem/dt/rails_health_checks.svg)](https://rubygems.org/gems/rails_health_checks)
[![ruby](https://img.shields.io/badge/ruby-%3E%3D%203.3-ruby.svg)](https://www.ruby-lang.org)
[![codecov](https://codecov.io/gh/eclectic-coding/rails_health_checks/branch/main/graph/badge.svg)](https://codecov.io/gh/eclectic-coding/rails_health_checks)

A Rails engine providing structured, pluggable health check endpoints for monitoring application status. Goes beyond Rails' built-in `/up` endpoint with per-check diagnostics, latency tracking, and a configurable check registry.

## Table of Contents

- [Installation](#installation)
- [Endpoints](#endpoints)
- [Configuration](#configuration)
- [Authentication](#authentication)
- [Built-in Checks](#built-in-checks)
- [Notifications](#notifications)
- [Prometheus Metrics](#prometheus-metrics)
- [Per-Environment Toggling](#per-environment-toggling)
- [Check Groups](#check-groups)
- [Custom Checks](#custom-checks)
- [Contributing](#contributing)
- [License](#license)

---

## Installation

Add to your Gemfile:

```ruby
gem "rails_health_checks"
```

Then run:

```bash
bundle install
```

Mount the engine in `config/routes.rb`:

```ruby
mount RailsHealthChecks::Engine => "/health"
```

Generate a commented initializer with all available options:

```bash
rails generate rails_health_checks:initializer
```

[↑ Back to top](#table-of-contents)

---

## Endpoints

| Endpoint | Format | Use case |
|----------|--------|----------|
| `GET /health` | JSON | Monitoring dashboards, detailed diagnostics |
| `GET /health/live` | Plain text | Load balancer liveness probes |
| `GET /health/metrics` | Prometheus text | Prometheus / OpenMetrics scraping |

`/health` and `/health/live` also respond to `HEAD` requests (useful for lightweight load balancer probes).

HTTP status is `200 OK` when all checks pass, `503 Service Unavailable` otherwise (except `/metrics` which always returns `200`).

### JSON response shape

```json
{
  "status": "ok",
  "timestamp": "2026-06-08T20:00:00Z",
  "checks": {
    "database": { "status": "ok", "latency_ms": 4 }
  }
}
```

Status values: `ok` | `degraded` | `critical`. Overall status is `critical` if any check is `critical`, `degraded` if any is `degraded`.

[↑ Back to top](#table-of-contents)

---

## Configuration

```ruby
# config/initializers/rails_health_checks.rb
RailsHealthChecks.configure do |config|
  config.checks         = [:database, :cache]  # checks to run (default: [:database])
  config.timeout        = 5                    # global timeout per check in seconds (default: 5)
  config.cache_duration = 10                   # cache results for N seconds (default: nil, disabled)
end
```

Configuration is validated at boot time. An unknown check name or a missing `http_url` for the `:http` check raises `RailsHealthChecks::ConfigurationError` on startup rather than silently failing on the first request.

[↑ Back to top](#table-of-contents)

---

## Authentication

By default health endpoints are public. Use one of the following strategies to restrict access. Unauthenticated requests receive `401 Unauthorized`.

### Bearer token

```ruby
RailsHealthChecks.configure do |config|
  config.token = ENV["HEALTH_TOKEN"]
end
```

Requests must include `Authorization: Bearer <token>`.

### IP allowlist

```ruby
RailsHealthChecks.configure do |config|
  config.allowed_ips = ["127.0.0.1", "10.0.0.0/8"]  # exact IPs or CIDR ranges
end
```

### Custom block

```ruby
RailsHealthChecks.configure do |config|
  config.authenticate { |request| request.headers["X-Internal"] == "true" }
end
```

The block receives the `ActionDispatch::Request` object and must return a truthy value to allow access.

[↑ Back to top](#table-of-contents)

---

## Built-in Checks

| Check | Description |
|-------|-------------|
| `:database` | ActiveRecord `SELECT 1` against the primary connection, includes latency |
| `:cache` | `Rails.cache` read/write probe; works with Redis, Memcached, or in-process store |
| `:sidekiq` | Sidekiq Redis connectivity; optional `config.sidekiq_queue_size` threshold for queue depth |
| `:solid_queue` | Solid Queue DB connectivity; optional `config.solid_queue_job_count` threshold for pending jobs |
| `:good_job` | GoodJob queue latency; optional `config.good_job_latency` (seconds) threshold for oldest pending job |
| `:resque` | Resque Redis connectivity; optional `config.resque_queue_size` threshold for total queue depth |
| `:disk` | Free disk bytes via `df`; optional `config.disk_warn_threshold` / `config.disk_critical_threshold` (bytes) and `config.disk_path` (default: `/`) |
| `:memory` | Process RSS via `ps`; optional `config.memory_threshold` (bytes) reports `degraded` when exceeded |
| `:http` | HTTP GET to `config.http_url`; reports `critical` if response code differs from `config.http_expected_status` (default: `200`) or a network error occurs; optional `config.http_headers` hash sends custom request headers (e.g. `{ "Authorization" => "Bearer ..." }`) |

[↑ Back to top](#table-of-contents)

---

## Notifications

Every health check run publishes an `ActiveSupport::Notifications` event:

```ruby
ActiveSupport::Notifications.subscribe("health_check.rails_health_checks") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  Rails.logger.info "Health check: #{event.payload[:status]} (#{event.duration.round}ms)"
  # event.payload[:checks] => { database: { status: "ok", latency_ms: 3 }, ... }
end
```

The payload includes `status` (overall: `ok`/`degraded`/`critical`) and `checks` (per-check hash with `status`, `latency_ms`, and `message` when present). Duration is measured over the entire parallel check run.

[↑ Back to top](#table-of-contents)

---

## Prometheus Metrics

`GET /health/metrics` returns Prometheus text exposition format (`text/plain; version=0.0.4`). This endpoint always returns HTTP 200 — Prometheus convention is that scrape targets should always respond successfully, with check state encoded in metric values.

```
# HELP rails_health_check_status Health check status (0=ok, 1=degraded, 2=critical)
# TYPE rails_health_check_status gauge
rails_health_check_status{check="database"} 0
rails_health_check_status{check="cache"} 0

# HELP rails_health_check_latency_ms Health check latency in milliseconds
# TYPE rails_health_check_latency_ms gauge
rails_health_check_latency_ms{check="database"} 4
rails_health_check_latency_ms{check="cache"} 2
```

[↑ Back to top](#table-of-contents)

---

## Per-Environment Toggling

Disable specific checks in specific environments:

```ruby
RailsHealthChecks.configure do |config|
  config.checks = [:database, :cache, :disk, :memory]
  config.disable :disk,   in: :test
  config.disable :memory, in: [:test, :development]
end
```

The check is removed from the active list only when `Rails.env` matches. The `in:` option accepts a single symbol or an array.

[↑ Back to top](#table-of-contents)

---

## Check Groups

Group related checks and expose them at a dedicated endpoint:

```ruby
RailsHealthChecks.configure do |config|
  config.group :system,  [:disk, :memory]
  config.group :workers, [:sidekiq, :good_job]
end
```

| Endpoint | Description |
|----------|-------------|
| `GET /health/system` | Runs only `:disk` and `:memory`, same JSON shape as `GET /health` |
| `GET /health/workers` | Runs only `:sidekiq` and `:good_job` |

Unknown group names return `404 Not Found`.

[↑ Back to top](#table-of-contents)

---

## Custom Checks

Define a class inheriting from `RailsHealthChecks::Check` and register it in your initializer:

```ruby
class MyApiCheck < RailsHealthChecks::Check
  def call
    res = Net::HTTP.get_response(URI("https://api.example.com/status"))
    res.code == "200" ? pass : fail_with("API returned #{res.code}")
  end
end

RailsHealthChecks.configure do |config|
  config.register :my_api, MyApiCheck.new
end
```

`config.register` automatically adds the check to the active checks list. Pass `timeout:` to override the global timeout for this check only:

```ruby
config.register :slow_api, MyApiCheck.new, timeout: 10
``` Use `pass`, `warn_with`, and `fail_with` (inherited from `Check`) to set status, and `measure { }` to record latency.

[↑ Back to top](#table-of-contents)

---

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

[↑ Back to top](#table-of-contents)

---

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
