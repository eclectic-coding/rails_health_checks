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

[↑ Back to top](#table-of-contents)

---

## Endpoints

| Endpoint | Format | Use case |
|----------|--------|----------|
| `GET /health` | JSON | Monitoring dashboards, detailed diagnostics |
| `GET /health/live` | Plain text | Load balancer liveness probes |

HTTP status is `200 OK` when all checks pass, `503 Service Unavailable` otherwise.

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
  config.checks  = [:database, :cache]  # checks to run (default: [:database])
  config.timeout = 5            # global timeout per check in seconds (default: 5)
end
```

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
| `:http` | HTTP GET to `config.http_url`; reports `critical` if response code differs from `config.http_expected_status` (default: `200`) or a network error occurs |

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

`config.register` automatically adds the check to the active checks list. Use `pass`, `warn_with`, and `fail_with` (inherited from `Check`) to set status, and `measure { }` to record latency.

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
