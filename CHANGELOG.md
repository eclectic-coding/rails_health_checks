# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `RailsHealthChecks::Rack::App` — a mountable Rack app that exposes the same four endpoints (`GET/HEAD /`, `GET/HEAD /live`, `GET /metrics`, `GET /:group`) for use in Sinatra, Roda, or plain Rack applications; opt-in via `require "rails_health_checks/rack/app"`; supports token auth, IP allowlist, custom auth block, result caching, and check groups; Rails-specific built-in checks (`:database`, `:cache`) require ActiveRecord/Rails in the stack but framework-agnostic checks (`:disk`, `:memory`, `:http`, `:redis`, `:smtp`) work in any Rack context

### Changed
- Relaxed Rails dependency from `>= 8.0` to `>= 7.1`; gem is now compatible with Rails 7.1, 7.2, and 8.x
- Added `concurrent-ruby >= 1.1` as an explicit runtime dependency (was previously an implicit transitive dependency through Rails)
- CI matrix expanded to test against Rails 7.1 and 7.2 on Ruby 3.3 and 3.4; Ruby 4.0 continues to test against Rails 8.x only
- Removed `factory_bot_rails` dev dependency — no factories exist in this gem and no specs use FactoryBot
- Removed explicit `rubocop-rails` dev dependency — it is a declared dependency of `rubocop-rails-omakase` and is installed transitively

## [1.0.1] - 2026-06-09

### Changed
- Updated gemspec summary and description to reflect the full 1.0.0 feature set

## [1.0.0] - 2026-06-09

### Added
- Built-in `:smtp` check that verifies mail server connectivity via `Net::SMTP` (stdlib, no extra gems); automatically reads `ActionMailer::Base.smtp_settings` when no explicit config is provided; optional `config.smtp_address` and `config.smtp_port` override the defaults (fallback: `localhost:25`)
- Built-in `:redis` check that pings a Redis server directly, independent of any job queue gem; requires the `redis` gem in the host app; optional `config.redis_url` overrides the `REDIS_URL` env var (default: `redis://localhost:6379/0`)
- `rails generate rails_health_checks:initializer` — generates a fully commented `config/initializers/rails_health_checks.rb` in the host app with all available configuration options documented inline
- Complete configuration reference table in README covering all config options with types, defaults, and descriptions
- Custom check authoring guide in README: full `Check` API reference (`pass`, `warn_with`, `fail_with`, `measure`), state contract, and testing patterns
- `MIGRATING_FROM_OKCOMPUTER.md`: complete migration guide from OkComputer with check name mappings, configuration translation, custom check migration, and response format differences
- Rails version CI matrix: test job now runs against `Gemfile` (latest Rails) and `gemfiles/rails_8_0.gemfile` (minimum supported Rails) across Ruby 3.3 and 3.4; Ruby 4.0 tested against latest Rails only
- Relaxed Rails dependency from `>= 8.1.3` to `>= 8.0` to support all currently-maintained Rails versions
- Performance benchmark suite (`benchmarks/benchmark.rb`, `bundle exec rake benchmark`): measures check run throughput, parallel execution speedup, and result cache effectiveness; results documented in `BENCHMARKS.md`

## [0.7.0] - 2026-06-09

### Added
- Result caching: `config.cache_duration = N` (seconds) caches check results in memory, avoiding re-running expensive checks on every request; disabled by default; keyed per check set so group endpoints cache independently; thread-safe
- HEAD request support on `GET /health` and `GET /health/live` for load balancer compatibility
- HTTP check custom headers: `config.http_headers = { "Authorization" => "Bearer ..." }` allows probing authenticated endpoints
- Boot-time configuration validation: raises `RailsHealthChecks::ConfigurationError` at app startup for unknown check names, `:http` check without `http_url`, and groups referencing missing checks

## [0.6.0] - 2026-06-09

### Added
- Prometheus metrics endpoint `GET /health/metrics` returning Prometheus text exposition format (`text/plain; version=0.0.4`); always returns HTTP 200; exposes `rails_health_check_status` (0=ok, 1=degraded, 2=critical) and `rails_health_check_latency_ms` gauges per check
- Parallel check execution via `Concurrent::Future` — all checks now run concurrently, reducing total response time from the sum of check latencies to roughly the slowest single check; `concurrent-ruby` is a transitive Rails dependency and requires no additional gem
- Per-check timeout: `config.register :slow_api, check, timeout: 10` overrides the global `config.timeout` for that specific check; checks without an explicit timeout continue to use the global value
- ActiveSupport::Notifications: publishes `health_check.rails_health_checks` on every check run; payload includes `status` (overall) and `checks` (per-check status, message, latency_ms); wraps the full execution so subscribers receive accurate duration

## [0.5.0] - 2026-06-09

### Added
- Custom check API: `config.register :name, MyCheck.new` registers a host-app check (subclass of `RailsHealthChecks::Check`) and appends it to the active checks list; the check is `dup`'d on each health request so state does not leak between calls
- Composite group API: `config.group :name, [:check_a, :check_b]` defines a named subset of checks exposed at `GET /health/:name`; returns the same JSON shape as `GET /health` but scoped to the group; unknown groups return `404`
- Per-environment toggling: `config.disable :check_name, in: :test` (or `in: [:test, :development]`) removes the check from the active list when `Rails.env` matches; filtering is applied at access time so check lists remain inspectable

## [0.4.0] - 2026-06-09

### Added
- Built-in `disk` check using `df -Pk` to measure free disk bytes; optional `config.disk_warn_threshold` reports `degraded` and `config.disk_critical_threshold` reports `critical` when free space falls below the configured byte thresholds; `config.disk_path` selects the mount point to check (default: `/`)
- Built-in `memory` check using `ps` to measure process RSS; optional `config.memory_threshold` (bytes) reports `degraded` when RSS exceeds the threshold
- Built-in `http` check performing an HTTP GET against `config.http_url`; reports `critical` when the response code differs from `config.http_expected_status` (default: `200`) or when a network error occurs

## [0.3.0] - 2026-06-09

### Added
- Built-in `cache` check using `Rails.cache` read/write probe; works with Redis, Memcached, or in-process store
- Built-in `sidekiq` check verifying Redis connectivity; optional `config.sidekiq_queue_size` threshold reports `degraded` when total queue depth exceeds it
- Built-in `solid_queue` check verifying DB connectivity via `SolidQueue::ReadyExecution.count`; optional `config.solid_queue_job_count` threshold reports `degraded` when pending jobs exceed it
- Built-in `good_job` check querying oldest pending `GoodJob::Job`; optional `config.good_job_latency` (seconds) reports `degraded` when queue latency exceeds it
- Built-in `resque` check verifying Redis connectivity via `Resque.redis.ping`; optional `config.resque_queue_size` threshold reports `degraded` when total queue depth exceeds it

## [0.2.0] - 2026-06-09

### Added
- Bearer token authentication via `config.token = ENV["HEALTH_TOKEN"]` (checked via `Authorization: Bearer <token>` header)
- IP allowlist authentication via `config.allowed_ips = ["127.0.0.1", "10.0.0.0/8"]` (CIDR ranges supported)
- Custom authentication block via `config.authenticate { |request| ... }`
- Unauthenticated requests return `401 Unauthorized`; no auth configured means public access

## [0.1.0] - 2026-06-08

### Added
- `GET /health` endpoint returning structured JSON with `ok`/`degraded`/`critical` status, per-check latency, and ISO8601 timestamp
- `GET /health/live` endpoint returning plain text `OK`/`Service Unavailable` for load balancer liveness probes
- Built-in `database` check using ActiveRecord `SELECT 1` with latency tracking
- Base `Check` class with `pass`, `warn_with`, `fail_with`, and `measure` helpers
- `CheckRegistry` for registering and running checks with global timeout and error isolation
- `ResponseBuilder` for composing JSON responses and HTTP status codes
- Configuration DSL via `RailsHealthChecks.configure` (`checks`, `timeout`)

[Unreleased]: https://github.com/eclectic-coding/rails_health_checks/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/eclectic-coding/rails_health_checks/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/eclectic-coding/rails_health_checks/releases/tag/v1.0.0
[0.7.0]: https://github.com/eclectic-coding/rails_health_checks/releases/tag/v0.7.0
[0.6.0]: https://github.com/eclectic-coding/rails_health_checks/releases/tag/v0.6.0
[0.5.0]: https://github.com/eclectic-coding/rails_health_checks/releases/tag/v0.5.0
[0.4.0]: https://github.com/eclectic-coding/rails_health_checks/releases/tag/v0.4.0
[0.3.0]: https://github.com/eclectic-coding/rails_health_checks/releases/tag/v0.3.0
[0.2.0]: https://github.com/eclectic-coding/rails_health_checks/releases/tag/v0.2.0
[0.1.0]: https://github.com/eclectic-coding/rails_health_checks/releases/tag/v0.1.0
