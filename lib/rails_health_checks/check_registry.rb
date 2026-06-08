# frozen_string_literal: true

require "timeout"

module RailsHealthChecks
  class CheckRegistry
    BUILT_INS = {
      database: -> { Checks::DatabaseCheck.new }
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
