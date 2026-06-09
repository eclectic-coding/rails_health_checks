# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/eclectic-coding/rails_health_checks/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/eclectic-coding/rails_health_checks/releases/tag/v0.4.0
[0.3.0]: https://github.com/eclectic-coding/rails_health_checks/releases/tag/v0.3.0
[0.2.0]: https://github.com/eclectic-coding/rails_health_checks/releases/tag/v0.2.0
[0.1.0]: https://github.com/eclectic-coding/rails_health_checks/releases/tag/v0.1.0
