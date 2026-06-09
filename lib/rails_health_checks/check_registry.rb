# frozen_string_literal: true

require "timeout"

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
      disk:        -> { Checks::DiskCheck.new(
        warn_threshold:     RailsHealthChecks.configuration.disk_warn_threshold,
        critical_threshold: RailsHealthChecks.configuration.disk_critical_threshold,
        path:               RailsHealthChecks.configuration.disk_path
      ) }
    }.freeze

    def self.build(check_names)
      check_names.each_with_object({}) do |name, hash|
        factory = BUILT_INS.fetch(name) do
          raise ArgumentError, "Unknown check: #{name}. Available: #{BUILT_INS.keys.join(', ')}"
        end
        hash[name] = factory.call
      end
    end

    def self.run(checks, timeout:)
      checks.transform_values { |check| run_check(check, timeout: timeout) }
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
