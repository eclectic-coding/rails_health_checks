# frozen_string_literal: true

module RailsHealthChecks
  class ApplicationController < ActionController::API
    include Authentication
    before_action :authenticate!

    private

    def run_checks(check_names)
      config = RailsHealthChecks.configuration

      if config.cache_duration
        cache_key = check_names.map(&:to_s).sort.join(",")
        RailsHealthChecks.result_cache.fetch(cache_key, ttl: config.cache_duration) do
          build_and_run(check_names, config)
        end
      else
        build_and_run(check_names, config)
      end
    end

    def build_and_run(check_names, config)
      checks = CheckRegistry.build(check_names)
      CheckRegistry.run(checks, timeout: config.timeout)
    end
  end
end
