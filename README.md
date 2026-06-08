# RailsHealthChecks

[![CI](https://github.com/eclectic-coding/rails_health_checks/actions/workflows/ci.yml/badge.svg)](https://github.com/eclectic-coding/rails_health_checks/actions/workflows/ci.yml)
[![gem](https://badge.fury.io/rb/rails_health_checks.svg)](https://badge.fury.io/rb/rails_health_checks)
[![downloads](https://img.shields.io/gem/dt/rails_health_checks.svg)](https://rubygems.org/gems/rails_health_checks)
[![ruby](https://img.shields.io/badge/ruby-%3E%3D%203.3-ruby.svg)](https://www.ruby-lang.org)
[![codecov](https://codecov.io/gh/eclectic-coding/rails_health_checks/branch/main/graph/badge.svg)](https://codecov.io/gh/eclectic-coding/rails_health_checks)

A Rails engine that provides configurable health check endpoints for monitoring application status.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "rails_health_checks"
```

Then execute:

```bash
bundle install
```

Mount the engine in `config/routes.rb`:

```ruby
mount RailsHealthChecks::Engine => "/health"
```

## Usage

Once mounted, the following endpoints are available:

| Endpoint       | Description                       |
|----------------|-----------------------------------|
| `GET /health`  | Overall application health status |

Responses return JSON with an HTTP status of `200 OK` (healthy) or `503 Service Unavailable` (unhealthy).

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).