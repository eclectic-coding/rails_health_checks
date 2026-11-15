# frozen_string_literal: true

require "timeout"
require "concurrent"

module RailsHealthChecks
  class CheckRegistry
    BUILT_INS = {
      database: -> { Checks::DatabaseCheck.new },
      cache:    -> { Checks::CacheCheck.new },
      redis:    -> { Checks::RedisCheck.new(url: RailsHealthChecks.configuration.redis_url) },
      smtp:     -> { Checks::SmtpCheck.new(
        address: RailsHealthChecks.configuration.smtp_address,
        port:    RailsHealthChecks.configuration.smtp_port
      ) },
      sidekiq:     -> { Checks::SidekiqCheck.new(queue_size: RailsHealthChecks.configuration.sidekiq_queue_size) },
      solid_queue: -> { Checks::SolidQueueCheck.new(job_count: RailsHealthChecks.configuration.solid_queue_job_count) },
      good_job:    -> { Checks::GoodJobCheck.new(latency: RailsHealthChecks.configuration.good_job_latency) },
      resque:      -> { Checks::ResqueCheck.new(queue_size: RailsHealthChecks.configuration.resque_queue_size) },
      memory:      -> { Checks::MemoryCheck.new(threshold: RailsHealthChecks.configuration.memory_threshold) },
      http:        -> { Checks::HttpCheck.new(
        url:             RailsHealthChecks.configuration.http_url,
        expected_status: RailsHealthChecks.configuration.http_expected_status,
        headers:         RailsHealthChecks.configuration.http_headers
      ) },
      disk:        -> { Checks::DiskCheck.new(
        warn_threshold:     RailsHealthChecks.configuration.disk_warn_threshold,
        critical_threshold: RailsHealthChecks.configuration.disk_critical_threshold,
        path:               RailsHealthChecks.configuration.disk_path
      ) }
    }.freeze

    def self.build(check_names)
      custom = RailsHealthChecks.configuration.custom_checks
      check_names.each_with_object({}) do |name, hash|
        if BUILT_INS.key?(name)
          hash[name] = BUILT_INS[name].call
        elsif custom.key?(name)
          hash[name] = custom[name].dup
        else
          available = (BUILT_INS.keys + custom.keys).join(", ")
          raise ArgumentError, "Unknown check: #{name}. Available: #{available}"
        end
      end
    end

    def self.run(checks, timeout:)
      results = {}
      instrument do |payload|
        futures = checks.transform_values do |check|
          t = check.timeout || timeout
          Concurrent::Future.execute { run_check(check, timeout: t) }
        end
        permit_concurrent_loads do
          checks.each do |name, check|
            t = check.timeout || timeout
            results[name] = futures[name].value(t + 1) || mark_critical(check, "timed out")
          end
        end
        if payload
          payload[:status] = overall_status(results)
          payload[:checks] = results.transform_values do |c|
            { status: c.status, message: c.message, latency_ms: c.latency_ms }.compact
          end
        end
      end
      results
    end

    def self.instrument(&block)
      if defined?(ActiveSupport::Notifications)
        ActiveSupport::Notifications.instrument("health_check.rails_health_checks", &block)
      else
        # simplecov:disable
        yield nil
        # simplecov:enable
      end
    end

    def self.run_check(check, timeout:)
      with_executor do
        Timeout.timeout(timeout) { check.call }
        check
      end
    rescue Timeout::Error
      mark_critical(check, "timed out")
    rescue StandardError => e
      mark_critical(check, e.message)
    end

    # Checks run on Concurrent's global pool, outside the request thread. Wrapping
    # each one in the Rails executor returns any Active Record connections it
    # leased (primary, cache, queue, ...) when the check finishes, including on
    # timeout; otherwise they stay checked out by the long-lived pool thread.
    def self.with_executor(&block)
      if defined?(Rails) && Rails.application
        Rails.application.executor.wrap(&block)
      else
        yield
      end
    end

    # In development the request thread holds the autoload interlock while it
    # waits on the futures; the check threads need it to load code, so let them.
    def self.permit_concurrent_loads(&block)
      if defined?(ActiveSupport::Dependencies) && ActiveSupport::Dependencies.respond_to?(:interlock)
        ActiveSupport::Dependencies.interlock.permit_concurrent_loads(&block)
      else
        yield
      end
    end

    def self.mark_critical(check, message)
      check.instance_variable_set(:@status, "critical")
      check.instance_variable_set(:@message, message)
      check
    end

    def self.overall_status(results)
      statuses = results.values.map(&:status)
      if statuses.include?("critical") then "critical"
      elsif statuses.include?("degraded") then "degraded"
      else "ok"
      end
    end

    private_class_method :run_check, :with_executor, :permit_concurrent_loads, :mark_critical, :overall_status, :instrument
  end
end
