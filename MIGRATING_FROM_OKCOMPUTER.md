# Migrating from OkComputer

This guide helps you migrate from [OkComputer](https://github.com/sportngin/okcomputer) to `rails_health_checks`.

## Table of Contents

- [Why Migrate](#why-migrate)
- [Installation Differences](#installation-differences)
- [Endpoint Mapping](#endpoint-mapping)
- [Check Name Mapping](#check-name-mapping)
- [Configuration Mapping](#configuration-mapping)
- [Custom Check Migration](#custom-check-migration)
- [Authentication Migration](#authentication-migration)
- [Response Format Differences](#response-format-differences)

---

## Why Migrate

| Feature | OkComputer | rails_health_checks |
|---------|------------|---------------------|
| Engine type | Mountable engine | Mountable engine |
| Response format | JSON / text | JSON / text / Prometheus |
| Check parallelism | Sequential | Parallel (`Concurrent::Future`) |
| Per-check latency | No | Yes (`latency_ms`) |
| Result caching | No | Yes (`config.cache_duration`) |
| `HEAD` support | No | Yes |
| Boot-time validation | No | Yes (raises on unknown check names) |
| Custom checks | `OkComputer::Check` subclass | `RailsHealthChecks::Check` subclass |
| ActiveSupport::Notifications | No | Yes |

---

## Installation Differences

**OkComputer:**

```ruby
# Gemfile
gem "okcomputer"

# config/routes.rb — auto-mounted, no explicit mount needed
```

**rails_health_checks:**

```ruby
# Gemfile
gem "rails_health_checks"

# config/routes.rb
mount RailsHealthChecks::Engine => "/health"
```

rails_health_checks requires an explicit `mount` so you control the path.

---

## Endpoint Mapping

| OkComputer endpoint | rails_health_checks equivalent |
|--------------------|-------------------------------|
| `GET /okcomputer` | `GET /health` |
| `GET /okcomputer/all` | `GET /health` |
| `GET /okcomputer/:check` | Not supported; use [check groups](README.md#check-groups) |
| (no Prometheus endpoint) | `GET /health/metrics` |
| (no liveness endpoint) | `GET /health/live` |

---

## Check Name Mapping

| OkComputer check class | rails_health_checks symbol | Notes |
|------------------------|---------------------------|-------|
| `OkComputer::ActiveRecordCheck` | `:database` | Runs `SELECT 1` on all configured connections |
| `OkComputer::CacheCheck` | `:cache` | Read/write probe via `Rails.cache` |
| `OkComputer::RedisCheck` | `:redis` | Requires `gem 'redis'`; set `config.redis_url` or `REDIS_URL` env |
| `OkComputer::SidekiqLatencyCheck` | `:sidekiq` | Set `config.sidekiq_queue_size` for depth threshold |
| `OkComputer::ResqueCheck` | `:resque` | Set `config.resque_queue_size` for depth threshold |
| `OkComputer::HttpCheck` | `:http` | Set `config.http_url` (required) |
| `OkComputer::MongoidCheck` | — | Not available; use a [custom check](README.md#custom-checks) |
| `OkComputer::ElasticsearchCheck` | — | Not available; use a [custom check](README.md#custom-checks) |
| `OkComputer::DelayedJobCheck` | — | Not available; use a [custom check](README.md#custom-checks) |
| (no equivalent) | `:smtp` | New: SMTP connectivity check |
| (no equivalent) | `:disk` | New: free disk space check |
| (no equivalent) | `:memory` | New: process RSS check |
| (no equivalent) | `:solid_queue` | New: SolidQueue check |
| (no equivalent) | `:good_job` | New: GoodJob check |

---

## Configuration Mapping

OkComputer registered checks inline in an initializer by calling class methods. rails_health_checks uses a single `configure` block with symbols.

**OkComputer style:**

```ruby
# config/initializers/okcomputer.rb
OkComputer.mount_at = "health"
OkComputer::Registry.register "database", OkComputer::ActiveRecordCheck.new
OkComputer::Registry.register "cache",    OkComputer::CacheCheck.new
OkComputer::Registry.register "redis",    OkComputer::RedisCheck.new(url: ENV["REDIS_URL"])
OkComputer::Registry.register "sidekiq",  OkComputer::SidekiqLatencyCheck.new("default", 100)
OkComputer::Registry.deregister "default"
OkComputer.make_optional %w[cache redis]
```

**rails_health_checks equivalent:**

```ruby
# config/initializers/rails_health_checks.rb
RailsHealthChecks.configure do |config|
  config.checks          = [:database, :cache, :redis, :sidekiq]
  config.redis_url       = ENV["REDIS_URL"]
  config.sidekiq_queue_size = 100
end
```

There is no concept of optional/required checks per endpoint — the overall HTTP status is `503` if any check is `critical`.

---

## Custom Check Migration

**OkComputer custom check:**

```ruby
class MyServiceCheck < OkComputer::Check
  def check
    response = Net::HTTP.get_response(URI("https://my-service.example.com/status"))
    if response.code.to_i == 200
      mark_message "my-service OK"
    else
      mark_failure
      mark_message "my-service returned #{response.code}"
    end
  end
end

OkComputer::Registry.register "my_service", MyServiceCheck.new
```

**rails_health_checks equivalent:**

```ruby
class MyServiceCheck < RailsHealthChecks::Check
  def call
    measure do
      response = Net::HTTP.get_response(URI("https://my-service.example.com/status"))
      if response.code.to_i == 200
        pass("my-service OK")
      else
        fail_with("my-service returned #{response.code}")
      end
    end
  rescue StandardError => e
    fail_with(e.message)
  end
end

RailsHealthChecks.configure do |config|
  config.register :my_service, MyServiceCheck.new
end
```

Key differences:

| OkComputer | rails_health_checks |
|------------|---------------------|
| `mark_message` | `pass(message)` |
| `mark_failure` | `fail_with(message)` |
| (no degraded state) | `warn_with(message)` for `degraded` |
| `mark_message` in `check` | `measure { }` block records `latency_ms` automatically |
| Register with `Registry.register` | `config.register :name, check_instance` |

---

## Authentication Migration

**OkComputer:**

```ruby
OkComputer.require_authentication("username", "password")
OkComputer.make_optional %w[all]  # or restrict specific checks
```

**rails_health_checks:**

```ruby
RailsHealthChecks.configure do |config|
  # Bearer token
  config.token = ENV["HEALTH_TOKEN"]

  # IP allowlist
  config.allowed_ips = ["127.0.0.1", "10.0.0.0/8"]

  # Custom block
  config.authenticate { |request| request.headers["X-Internal"] == "true" }
end
```

rails_health_checks does not support HTTP Basic Auth natively. If you need it, use the `authenticate` block:

```ruby
config.authenticate do |request|
  credentials = ActionController::HttpAuthentication::Basic.decode_credentials(request)
  credentials == "username:password"
end
```

---

## Response Format Differences

OkComputer returns plain text by default; JSON on request. rails_health_checks always returns JSON from `GET /health`.

**OkComputer JSON (`GET /okcomputer.json`):**

```json
{
  "default": {
    "message": "Database connected",
    "failure": false
  }
}
```

**rails_health_checks JSON (`GET /health`):**

```json
{
  "status": "ok",
  "timestamp": "2026-06-08T20:00:00Z",
  "checks": {
    "database": { "status": "ok", "latency_ms": 4 }
  }
}
```

Status values map as follows:

| OkComputer `failure` | rails_health_checks `status` |
|---------------------|------------------------------|
| `false` | `"ok"` |
| `true` | `"critical"` |
| (no equivalent) | `"degraded"` |