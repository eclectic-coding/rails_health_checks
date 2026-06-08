# frozen_string_literal: true

module RailsHealthChecks
  class HealthController < ApplicationController
    def show
      builder = ResponseBuilder.new(run_checks)
      render json: builder.to_json, status: builder.http_status
    end

    def live
      builder = ResponseBuilder.new(run_checks)
      if builder.overall_status == 'ok'
        render plain: 'OK', status: :ok
      else
        render plain: 'Service Unavailable', status: :service_unavailable
      end
    end

    private

    def run_checks
      config = RailsHealthChecks.configuration
      checks = CheckRegistry.build(config.checks)
      CheckRegistry.run(checks, timeout: config.timeout)
    end
  end
end
