# frozen_string_literal: true

module RailsHealthChecks
  module Checks
    class CacheCheck < Check
      PROBE_KEY = "rails_health_checks:cache_probe"
      PROBE_VALUE = "ok"

      def call
        measure do
          Rails.cache.write(PROBE_KEY, PROBE_VALUE, expires_in: 10)
          result = Rails.cache.read(PROBE_KEY)
          raise "unexpected value: #{result.inspect}" unless result == PROBE_VALUE
        end
        pass
      rescue StandardError => e
        fail_with(e.message)
      end
    end
  end
end
