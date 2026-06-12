# Roadmap

Rails 7.1 added a basic `/up` endpoint via `Rails::HealthController`, but it only verifies the app boots — no dependency checks, no pluggability, no configuration. `rails_health_checks` fills that gap as a production-grade, extensible health check engine with pluggable checks, a clean configuration DSL, and structured JSON responses that monitoring tools can consume.

---

## Planned Features

### Two-tier health check endpoints

Expose two distinct endpoint tiers to match the two common health check use cases:

- **Shallow / liveness endpoint** (`/health` or `/up`) — checks only that the Ruby process is alive. Safe to use as a Kubernetes `livenessProbe` or load balancer health check, because dependency failures (DB blip, Redis timeout) won't cause the load balancer to eject all nodes simultaneously and turn a brief outage into a full one.
- **Deep / readiness endpoint** (`/health/ready` or configurable) — runs all configured checks (database, Redis, etc.). Intended for external monitors (Pingdom, etc.), Kubernetes `readinessProbe`, or any context where full-stack health is what you want to know about.

The documentation should clearly explain *why* to use each tier, not just how — the cascade failure footgun (DB blip → all nodes fail health check → load balancer ejects all nodes → pods restart) is subtle and not obvious to developers until it happens in production.

---

Feature requests and bug reports are welcome via [GitHub Issues](https://github.com/eclectic-coding/rails_health_checks/issues).
