# frozen_string_literal: true

require "timeout"
require "concurrent"

module RailsHealthChecks
  class CheckRegistry
    BUILT_INS = {
      database: -> { Checks::DatabaseCheck.new },
      cache:    -> { Checks::CacheCheck.new },
      sidekiq:     -> { Checks::SidekiqCheck.new(queue_size: RailsHealthChecks.configuration.sidekiq_queue_size) },
      solid_queue: -> { Checks::SolidQueueCheck.new(job_count: RailsHealthChecks.configuration.solid_queue_job_count) },
      good_job:    -> { Checks::GoodJobCheck.new(latency: RailsHealthChecks.configuration.good_job_latency) },
      resque:      -> { Checks::ResqueCheck.new(queue_size: RailsHealthChecks.configuration.resque_queue_size) },
      memory:      -> { Checks::MemoryCheck.new(threshold: RailsHealthChecks.configuration.memory_threshold) },
      http:        -> { Checks::HttpCheck.new(
        url:             RailsHealthChecks.configuration.http_url,
        expected_status: RailsHealthChecks.configuration.http_expected_status
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
      futures = checks.transform_values { |check| Concurrent::Future.execute { run_check(check, timeout: timeout) } }
      checks.each_with_object({}) do |(name, check), results|
        results[name] = futures[name].value(timeout + 1) || mark_critical(check, "timed out")
      end
    end

    def self.run_check(check, timeout:)
      Timeout.timeout(timeout) { check.call }
      check
    rescue Timeout::Error
      mark_critical(check, "timed out")
    rescue StandardError => e
      mark_critical(check, e.message)
    end

    def self.mark_critical(check, message)
      check.instance_variable_set(:@status, "critical")
      check.instance_variable_set(:@message, message)
      check
    end

    private_class_method :run_check, :mark_critical
  end
end
