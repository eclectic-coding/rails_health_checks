# frozen_string_literal: true

RailsHealthChecks.configure do |config|
  config.checks = [:database, :cache, :disk, :memory, :http]

  config.http_url             = "http://localhost:3000/health/live"
  config.http_expected_status = 200

  config.disk_warn_threshold     = 1 * 1024**3  # 1 GB → degraded
  config.disk_critical_threshold = 512 * 1024**2 # 512 MB → critical

  config.memory_threshold = 512 * 1024**2 # 512 MB → degraded
end