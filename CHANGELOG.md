# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/eclectic-coding/rails_health_checks/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/eclectic-coding/rails_health_checks/releases/tag/v0.1.0
