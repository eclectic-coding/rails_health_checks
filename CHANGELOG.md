# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
