#!/usr/bin/env ruby
# frozen_string_literal: true

# Run with: bundle exec rake benchmark
# Or directly: bundle exec ruby benchmarks/benchmark.rb

ENV["RAILS_ENV"] = "test"
require_relative "../spec/dummy/config/environment"
require "benchmark"
require "benchmark/ips"

puts "=== rails_health_checks benchmarks ==="
puts "Ruby  #{RUBY_VERSION}"
puts "Rails #{Rails.version}"
puts

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

class NullCheck < RailsHealthChecks::Check
  def call = measure { pass("ok") }
end

class DelayedCheck < RailsHealthChecks::Check
  def initialize(delay_ms:)
    @delay_ms = delay_ms
  end

  def call
    measure { sleep(@delay_ms / 1000.0) }
    pass("ok")
  end
end

def null_checks(n)
  n.times.each_with_object({}) { |i, h| h[:"check_#{i}"] = NullCheck.new }
end

def run(checks)
  RailsHealthChecks::CheckRegistry.run(checks.transform_values(&:dup), timeout: 5)
end

# ---------------------------------------------------------------------------
# 1. Check run throughput (no I/O)
# ---------------------------------------------------------------------------
puts "== 1. Throughput — NullCheck (no I/O) =="
puts "   Measures gem overhead: registry lookup, Concurrent::Future scheduling,"
puts "   result aggregation, and ActiveSupport::Notifications instrumentation."
puts

single = null_checks(1)
five   = null_checks(5)
ten    = null_checks(10)

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)
  x.report("1 check ") { run(single) }
  x.report("5 checks") { run(five) }
  x.report("10 checks") { run(ten) }
  x.compare!
end

# ---------------------------------------------------------------------------
# 2. Parallel vs sequential
# ---------------------------------------------------------------------------
puts "\n== 2. Parallel execution — 5 checks × 10ms simulated latency =="
puts "   Shows the speedup from Concurrent::Future parallel execution."
puts

slow = 5.times.each_with_object({}) { |i, h| h[:"slow_#{i}"] = DelayedCheck.new(delay_ms: 10) }

sequential_ms = Benchmark.measure do
  slow.each_value { |c| c.dup.tap(&:call) }
end.real * 1000

parallel_ms = Benchmark.measure do
  RailsHealthChecks::CheckRegistry.run(slow.transform_values(&:dup), timeout: 5)
end.real * 1000

puts format("  Sequential : %6.1f ms  (sum of individual check durations)", sequential_ms)
puts format("  Parallel   : %6.1f ms  (wall-clock with Concurrent::Future)", parallel_ms)
puts format("  Speedup    : %6.1fx", sequential_ms / parallel_ms)

# ---------------------------------------------------------------------------
# 3. Result cache
# ---------------------------------------------------------------------------
puts "\n== 3. Result cache — 5 NullChecks, TTL 60s =="
puts "   Compares a cold run (checks execute) against a cache hit (mutex + hash lookup)."
puts

cache     = RailsHealthChecks::ResultCache.new
cache_key = "check_0,check_1,check_2,check_3,check_4"
cached    = null_checks(5)

# Pre-warm the cache so the hit path always returns cached results
cache.fetch(cache_key, ttl: 60) { run(cached) }

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report("cache miss (run checks)") do
    run(cached)
  end

  x.report("cache hit  (TTL 60s)   ") do
    cache.fetch(cache_key, ttl: 60) { run(cached) }
  end

  x.compare!
end
