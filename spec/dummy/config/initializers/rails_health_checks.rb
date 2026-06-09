# frozen_string_literal: true

class AppStatusCheck < RailsHealthChecks::Check
  def call
    measure { }
    pass "app is running"
  end
end

RailsHealthChecks.configure do |config|
  config.checks = [:database, :cache, :disk, :memory]

  config.disk_warn_threshold     = 1 * 1024**3  # 1 GB → degraded
  config.disk_critical_threshold = 512 * 1024**2 # 512 MB → critical

  config.memory_threshold = 512 * 1024**2 # 512 MB → degraded

  config.register :app_status, AppStatusCheck.new
end