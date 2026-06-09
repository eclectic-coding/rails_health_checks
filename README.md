# RailsHealthChecks

[![CI](https://github.com/eclectic-coding/rails_health_checks/actions/workflows/ci.yml/badge.svg)](https://github.com/eclectic-coding/rails_health_checks/actions/workflows/ci.yml)
[![gem](https://img.shields.io/gem/v/rails_health_checks.svg)](https://rubygems.org/gems/rails_health_checks)
[![downloads](https://img.shields.io/gem/dt/rails_health_checks.svg)](https://rubygems.org/gems/rails_health_checks)
[![ruby](https://img.shields.io/badge/ruby-%3E%3D%203.3-ruby.svg)](https://www.ruby-lang.org)
[![codecov](https://codecov.io/gh/eclectic-coding/rails_health_checks/branch/main/graph/badge.svg)](https://codecov.io/gh/eclectic-coding/rails_health_checks)

A Rails engine that adds production-grade health check endpoints to any Rails app. Goes well beyond the built-in `/up` endpoint with 11 built-in checks, parallel execution, structured JSON responses, Prometheus metrics, and a clean configuration DSL.

**Built-in checks:** database · cache · Redis · SMTP · Sidekiq · SolidQueue · GoodJob · Resque · disk · memory · HTTP

**Key features:**
- Parallel check execution via `Concurrent::Future` — response time bounded by the slowest check, not the sum
- Result caching (`config.cache_duration`) to absorb high-frequency probe traffic
- Prometheus text exposition at `GET /health/metrics` (always HTTP 200)
- Check groups (`config.group`) expose subsets at `/health/:group`
- Per-environment toggling, boot-time validation, and bearer token / IP / custom auth
- `rails generate rails_health_checks:initializer` scaffolds a fully-commented config file
- Drop-in replacement for OkComputer — see [MIGRATING_FROM_OKCOMPUTER.md](MIGRATING_FROM_OKCOMPUTER.md)

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
- [Performance](#performance)
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

Run the initializer generator to create `config/initializers/rails_health_checks.rb` with every option documented as a commented example:

```bash
rails generate rails_health_checks:initializer
```

The generated file (shown below with all options) uses the block-style `configure` API. Every setting has a sensible default — uncomment only what you need:

```ruby
# frozen_string_literal: true

RailsHealthChecks.configure do |config|
  # Checks to run (default: [:database])
  # Available built-ins: :database, :cache, :redis, :smtp, :sidekiq, :solid_queue,
  #                      :good_job, :resque, :disk, :memory, :http
  config.checks = [:database]

  # Global timeout per check in seconds (default: 5)
  config.timeout = 5

  # Cache check results for N seconds to avoid re-running on every request (default: nil, disabled)
  # config.cache_duration = 10

  # ---------------------------------------------------------------------------
  # Authentication — all strategies are mutually exclusive; default is public
  # ---------------------------------------------------------------------------

  # Bearer token: requests must include Authorization: Bearer <token>
  # config.token = ENV["HEALTH_TOKEN"]

  # IP allowlist: exact IPs or CIDR ranges
  # config.allowed_ips = ["127.0.0.1", "10.0.0.0/8"]

  # Custom block: return truthy to allow the request
  # config.authenticate { |request| request.headers["X-Internal"] == "true" }

  # ---------------------------------------------------------------------------
  # Per-environment toggling
  # ---------------------------------------------------------------------------
  # config.disable :disk,   in: :test
  # config.disable :memory, in: [:test, :development]

  # ---------------------------------------------------------------------------
  # Check groups — expose subsets at GET /health/:group
  # ---------------------------------------------------------------------------
  # config.group :system,  [:disk, :memory]
  # config.group :workers, [:sidekiq, :good_job]

  # ---------------------------------------------------------------------------
  # Redis check (requires :redis in config.checks and the redis gem)
  # ---------------------------------------------------------------------------
  # config.redis_url = ENV["REDIS_URL"]         # default: redis://localhost:6379/0

  # ---------------------------------------------------------------------------
  # SMTP check (requires :smtp in config.checks)
  # Reads ActionMailer::Base.smtp_settings automatically if not set here.
  # ---------------------------------------------------------------------------
  # config.smtp_address = "smtp.example.com"  # default: ActionMailer config or localhost
  # config.smtp_port    = 587                 # default: ActionMailer config or 25

  # ---------------------------------------------------------------------------
  # Disk check (requires :disk in config.checks)
  # ---------------------------------------------------------------------------
  # config.disk_path               = "/"             # mount point (default: "/")
  # config.disk_warn_threshold     = 2 * 1024**3     # bytes free → degraded
  # config.disk_critical_threshold = 512 * 1024**2   # bytes free → critical

  # ---------------------------------------------------------------------------
  # Memory check (requires :memory in config.checks)
  # ---------------------------------------------------------------------------
  # config.memory_threshold = 512 * 1024**2          # RSS bytes → degraded

  # ---------------------------------------------------------------------------
  # HTTP check (requires :http in config.checks)
  # ---------------------------------------------------------------------------
  # config.http_url             = "https://api.example.com/status"
  # config.http_expected_status = 200                # expected response code (default: 200)
  # config.http_headers         = { "Authorization" => "Bearer #{ENV['API_TOKEN']}" }

  # ---------------------------------------------------------------------------
  # Sidekiq check (requires :sidekiq in config.checks)
  # ---------------------------------------------------------------------------
  # config.sidekiq_queue_size = 1000                 # total depth → degraded

  # ---------------------------------------------------------------------------
  # Solid Queue check (requires :solid_queue in config.checks)
  # ---------------------------------------------------------------------------
  # config.solid_queue_job_count = 500               # pending jobs → degraded

  # ---------------------------------------------------------------------------
  # GoodJob check (requires :good_job in config.checks)
  # ---------------------------------------------------------------------------
  # config.good_job_latency = 300                    # seconds oldest job waiting → degraded

  # ---------------------------------------------------------------------------
  # Resque check (requires :resque in config.checks)
  # ---------------------------------------------------------------------------
  # config.resque_queue_size = 1000                  # total depth → degraded

  # ---------------------------------------------------------------------------
  # Custom checks
  # ---------------------------------------------------------------------------
  # class MyApiCheck < RailsHealthChecks::Check
  #   def call
  #     res = Net::HTTP.get_response(URI("https://api.example.com/status"))
  #     res.code == "200" ? pass : fail_with("API returned #{res.code}")
  #   end
  # end
  #
  # config.register :my_api, MyApiCheck.new
  # config.register :slow_api, MyApiCheck.new, timeout: 10  # per-check timeout override
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

## Performance

See [BENCHMARKS.md](BENCHMARKS.md) for throughput numbers, parallel execution speedup, and cache effectiveness measurements. To run the suite locally:

```bash
bundle exec rake benchmark
```

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