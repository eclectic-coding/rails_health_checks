# RailsHealthChecks

[![CI](https://github.com/eclectic-coding/rails_health_checks/actions/workflows/ci.yml/badge.svg)](https://github.com/eclectic-coding/rails_health_checks/actions/workflows/ci.yml)
[![gem](https://badge.fury.io/rb/rails_health_checks.svg)](https://badge.fury.io/rb/rails_health_checks)
[![downloads](https://img.shields.io/gem/dt/rails_health_checks.svg)](https://rubygems.org/gems/rails_health_checks)
[![ruby](https://img.shields.io/badge/ruby-%3E%3D%203.3-ruby.svg)](https://www.ruby-lang.org)
[![codecov](https://codecov.io/gh/eclectic-coding/rails_health_checks/branch/main/graph/badge.svg)](https://codecov.io/gh/eclectic-coding/rails_health_checks)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Rails engine providing structured, pluggable health check endpoints for monitoring application status. Goes beyond Rails' built-in `/up` endpoint with per-check diagnostics, latency tracking, and a configurable check registry.

## Table of Contents

- [Installation](#installation)
- [Endpoints](#endpoints)
- [Configuration](#configuration)
- [Built-in Checks](#built-in-checks)
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
  config.checks  = [:database]  # checks to run (default: [:database])
  config.timeout = 5            # global timeout per check in seconds (default: 5)
end
```

[↑ Back to top](#table-of-contents)

---

## Built-in Checks

| Check | Description |
|-------|-------------|
| `:database` | ActiveRecord `SELECT 1` against the primary connection, includes latency |

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
