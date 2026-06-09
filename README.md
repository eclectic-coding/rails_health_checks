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
  - [Configuration Reference](#configuration-reference)
- [Authentication](#authentication)
- [Built-in Checks](#built-in-checks)
- [Notifications](#notifications)
- [Prometheus Metrics](#prometheus-metrics)
- [Result Caching](#result-caching)
- [Per-Environment Toggling](#per-environment-toggling)
- [Check Groups](#check-groups)
- [Custom Checks](#custom-checks)
  - [Check API](#check-api)
  - [Testing Custom Checks](#testing-custom-checks)
- [Migrating from OkComputer](#migrating-from-okcomputer)
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
| `GET /health/:group` | JSON | Scoped check group (e.g. `/health/workers`) |

`/health` and `/health/live` also respond to `HEAD` requests (useful for lightweight load balancer probes).

HTTP status is `200 OK` when all checks pass, `503 Service Unavailable` otherwise (except `/metrics` which always returns `200`).

### JSON response shape

```json
{
  "status": "ok",
  "timestamp": "2026-06-08T20:00:00Z",
  "checks": {
    "database": { "status": "ok", "latency_ms": 4 },
    "cache":    { "status": "ok", "latency_ms": 1 }
  }
}
```

Status values: `ok` | `degraded` | `critical`. Overall status is `critical` if any check is `critical`, `degraded` if any is `degraded`, `ok` otherwise.

[↑ Back to top](#table-of-contents)

---

## Configuration

```ruby
# config/initializers/rails_health_checks.rb
RailsHealthChecks.configure do |config|
  config.checks         = [:database, :cache, :redis]
  config.timeout        = 5
  config.cache_duration = 10
end
```

Configuration is validated at boot time. An unknown check name, a missing `http_url` for the `:http` check, or a group referencing an undefined check raises `RailsHealthChecks::ConfigurationError` on startup rather than silently failing on the first request.

### Configuration Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `checks` | `Array` | `[:database]` | Built-in or custom check names to run |
| `timeout` | `Integer` | `5` | Global per-check timeout in seconds |
| `cache_duration` | `Integer\|nil` | `nil` | Cache results for N seconds; `nil` disables caching |
| `token` | `String\|nil` | `nil` | Bearer token for authentication |
| `allowed_ips` | `Array\|nil` | `nil` | IP allowlist; accepts exact IPs and CIDR ranges |
| `redis_url` | `String\|nil` | `nil` | Redis URL for `:redis` check; falls back to `REDIS_URL` env var then `redis://localhost:6379/0` |
| `smtp_address` | `String\|nil` | `nil` | SMTP host for `:smtp` check; falls back to `ActionMailer` config then `localhost` |
| `smtp_port` | `Integer\|nil` | `nil` | SMTP port for `:smtp` check; falls back to `ActionMailer` config then `25` |
| `sidekiq_queue_size` | `Integer\|nil` | `nil` | Total Sidekiq queue depth that triggers `degraded` |
| `solid_queue_job_count` | `Integer\|nil` | `nil` | Pending SolidQueue jobs that trigger `degraded` |
| `good_job_latency` | `Integer\|nil` | `nil` | Oldest pending GoodJob age (seconds) that triggers `degraded` |
| `resque_queue_size` | `Integer\|nil` | `nil` | Total Resque queue depth that triggers `degraded` |
| `disk_path` | `String` | `"/"` | Mount point for `:disk` check |
| `disk_warn_threshold` | `Integer\|nil` | `nil` | Free bytes below which `:disk` reports `degraded` |
| `disk_critical_threshold` | `Integer\|nil` | `nil` | Free bytes below which `:disk` reports `critical` |
| `memory_threshold` | `Integer\|nil` | `nil` | Process RSS bytes above which `:memory` reports `degraded` |
| `http_url` | `String\|nil` | `nil` | Target URL for `:http` check (**required** when `:http` is active) |
| `http_expected_status` | `Integer` | `200` | Expected HTTP response code for `:http` check |
| `http_headers` | `Hash` | `{}` | Request headers sent by `:http` check |

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

| Check | Requires | Description |
|-------|----------|-------------|
| `:database` | — | ActiveRecord `SELECT 1` against the primary connection |
| `:cache` | — | `Rails.cache` read/write probe; works with any cache store |
| `:redis` | `redis` gem | Direct Redis `PING`; `config.redis_url` or `REDIS_URL` env var |
| `:smtp` | — | SMTP connectivity via `Net::SMTP`; reads `ActionMailer` config automatically |
| `:sidekiq` | `sidekiq` gem | Sidekiq Redis connectivity; optional `config.sidekiq_queue_size` depth threshold |
| `:solid_queue` | `solid_queue` gem | SolidQueue DB connectivity; optional `config.solid_queue_job_count` threshold |
| `:good_job` | `good_job` gem | GoodJob queue latency; optional `config.good_job_latency` (seconds) threshold |
| `:resque` | `resque` gem | Resque Redis connectivity; optional `config.resque_queue_size` depth threshold |
| `:disk` | — | Free disk space via `df`; `config.disk_warn_threshold` / `config.disk_critical_threshold` (bytes) |
| `:memory` | — | Process RSS via `ps`; optional `config.memory_threshold` (bytes) reports `degraded` when exceeded |
| `:http` | — | HTTP GET to `config.http_url`; `config.http_expected_status` and `config.http_headers` |

All checks run in parallel. Each check times out independently using `config.timeout` (default: 5s) or a per-check override set via `config.register`.

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

The payload includes:

| Key | Value |
|-----|-------|
| `status` | Overall status: `"ok"`, `"degraded"`, or `"critical"` |
| `checks` | Hash of `{ check_name => { status:, latency_ms:, message: } }` |

`duration` on the event covers the entire parallel check run, not individual checks.

[↑ Back to top](#table-of-contents)

---

## Prometheus Metrics

`GET /health/metrics` returns Prometheus text exposition format (`text/plain; version=0.0.4`). This endpoint always returns HTTP 200 per Prometheus scraping convention — check state is encoded in metric values.

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

Latency lines are omitted for checks that do not call `measure { }`.

[↑ Back to top](#table-of-contents)

---

## Result Caching

By default every request re-runs all checks. Set `cache_duration` to serve cached results for N seconds, reducing load on the database, Redis, and other dependencies:

```ruby
RailsHealthChecks.configure do |config|
  config.cache_duration = 10  # seconds
end
```

The cache is keyed per check set — `GET /health` and `GET /health/workers` cache independently. The cache is in-process (not shared across dynos/containers), so each instance maintains its own result window.

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

| Endpoint | Runs |
|----------|------|
| `GET /health/system` | `:disk`, `:memory` |
| `GET /health/workers` | `:sidekiq`, `:good_job` |

The response shape is identical to `GET /health`. Unknown group names return `404 Not Found`.

[↑ Back to top](#table-of-contents)

---

## Custom Checks

### Authoring

Define a class inheriting from `RailsHealthChecks::Check`, implement `call`, and register it:

```ruby
class PaymentGatewayCheck < RailsHealthChecks::Check
  def call
    measure do
      response = Net::HTTP.get_response(URI("https://api.stripe.com/v1/charges"))
      case response.code.to_i
      when 200, 401  # 401 = auth error, but gateway is reachable
        pass
      when 429
        warn_with("rate limited (429)")
      else
        fail_with("unexpected status #{response.code}")
      end
    end
  rescue StandardError => e
    fail_with(e.message)
  end
end

RailsHealthChecks.configure do |config|
  config.register :payment_gateway, PaymentGatewayCheck.new
  config.register :slow_gateway,    PaymentGatewayCheck.new, timeout: 15
end
```

`config.register` appends the check to the active list automatically.

### Check API

| Method | Status set | Use when |
|--------|-----------|----------|
| `pass(message = nil)` | `ok` | Check passed; optional message |
| `warn_with(message)` | `degraded` | Check is functional but degraded |
| `fail_with(message)` | `critical` | Check failed; service is impaired |
| `measure { }` | — | Wraps a block and records `latency_ms` |

**State contract:** call exactly one of `pass`, `warn_with`, or `fail_with` per `call` invocation. The check instance is `dup`'d before each run, so instance variables set during one request do not bleed into the next.

### Testing Custom Checks

Call the check directly in a unit test — no request stack needed:

```ruby
RSpec.describe PaymentGatewayCheck do
  subject(:check) { described_class.new }

  context "when the gateway is reachable" do
    before do
      stub_request(:get, "https://api.stripe.com/v1/charges")
        .to_return(status: 200)
    end

    it "passes" do
      check.call
      expect(check.status).to eq("ok")
    end
  end

  context "when the gateway is rate-limited" do
    before do
      stub_request(:get, "https://api.stripe.com/v1/charges")
        .to_return(status: 429)
    end

    it "warns" do
      check.call
      expect(check.status).to eq("degraded")
      expect(check.message).to include("rate limited")
    end
  end
end
```

[↑ Back to top](#table-of-contents)

---

## Migrating from OkComputer

See [MIGRATING_FROM_OKCOMPUTER.md](MIGRATING_FROM_OKCOMPUTER.md) for a full mapping of check names, configuration keys, and endpoint differences.

Quick reference:

| OkComputer | rails_health_checks |
|------------|---------------------|
| `OkComputer::ActiveRecordCheck` | `:database` |
| `OkComputer::CacheCheck` | `:cache` |
| `OkComputer::RedisCheck` | `:redis` |
| `OkComputer::SidekiqLatencyCheck` | `:sidekiq` + `config.sidekiq_queue_size` |
| `OkComputer::HttpCheck` | `:http` + `config.http_url` |
| `OkComputer::CustomCheck` subclass | Subclass `RailsHealthChecks::Check` |
| `GET /okcomputer` | `GET /health` |
| `GET /okcomputer/all` | `GET /health` |

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