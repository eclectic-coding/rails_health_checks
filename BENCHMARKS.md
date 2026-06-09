# Benchmarks

Performance characteristics of `rails_health_checks`. Run the suite yourself to get numbers representative of your hardware:

```bash
bundle exec rake benchmark
```

---

## Environment

Results below were captured on Apple M-series hardware:

```
Ruby  4.0.5 +YJIT
Rails 8.1.3
```

---

## 1. Check run throughput (no I/O)

Measures gem overhead per run: registry lookup, `Concurrent::Future` scheduling, result aggregation, and `ActiveSupport::Notifications` instrumentation. Uses a `NullCheck` that immediately calls `pass` — no database, cache, or network involved.

```
Warming up --------------------------------------
            1 check      3.894k i/100ms
            5 checks   934.000 i/100ms
           10 checks   541.000 i/100ms
Calculating -------------------------------------
            1 check      42.640k (± 5.3%) i/s   (23.45 μs/i)
            5 checks      9.777k (± 4.5%) i/s  (102.28 μs/i)
           10 checks      5.643k (± 3.2%) i/s  (177.21 μs/i)

Comparison:
 1 check :    42639.7 i/s
 5 checks:     9777.4 i/s - 4.36x  slower
10 checks:     5642.9 i/s - 7.56x  slower
```

**Interpretation:** A single check run costs ~23 µs in overhead. With 5 checks running in parallel the wall-clock cost is ~102 µs — well under 1ms for the pure framework overhead before any real I/O.

---

## 2. Parallel execution speedup

Five `DelayedCheck` instances each sleeping 10ms, run sequentially versus in parallel via `Concurrent::Future`.

```
  Sequential :   60.9 ms  (sum of individual check durations)
  Parallel   :   13.4 ms  (wall-clock with Concurrent::Future)
  Speedup    :    4.5x
```

**Interpretation:** With 5 checks that each take 10ms, sequential execution takes the full sum (~50ms+). Parallel execution reduces total wall-clock time to roughly the slowest single check (~10ms), yielding a ~4.5x speedup. The more checks you add, the greater the benefit.

---

## 3. Result cache effectiveness

Five `NullCheck` instances with a 60-second TTL cache. The "hit" path is a mutex-guarded hash lookup; the "miss" path runs all checks.

```
Warming up --------------------------------------
cache miss (run checks)   997.000 i/100ms
cache hit  (TTL 60s)      442.448k i/100ms
Calculating -------------------------------------
cache miss (run checks)     10.047k (± 6.4%) i/s   (99.53 μs/i)
cache hit  (TTL 60s)         4.363M (± 3.9%) i/s  (229.21 ns/i)

Comparison:
cache hit  (TTL 60s)   :  4362739.4 i/s
cache miss (run checks):    10047.3 i/s - 434.22x  slower
```

**Interpretation:** A cache hit costs ~229 ns — effectively free. Even for NullChecks with no real I/O, caching delivers a 434× throughput improvement. For checks that hit real services (database, Redis, SMTP) the gap is far larger. Set `config.cache_duration = 10` to absorb high-frequency health endpoint traffic without adding load to your dependencies.