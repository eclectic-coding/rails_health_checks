# frozen_string_literal: true

module RailsHealthChecks
  class ApplicationController < ActionController::API
    include Authentication
    before_action :authenticate!

    private

    def run_checks(check_names)
      config = RailsHealthChecks.configuration
      checks = CheckRegistry.build(check_names)
      CheckRegistry.run(checks, timeout: config.timeout)
    end
  end
end
