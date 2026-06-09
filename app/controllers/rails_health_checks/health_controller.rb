# frozen_string_literal: true

module RailsHealthChecks
  class HealthController < ApplicationController
    def show
      builder = ResponseBuilder.new(run_checks(RailsHealthChecks.configuration.checks))
      render json: builder.to_json, status: builder.http_status
    end

    def live
      builder = ResponseBuilder.new(run_checks(RailsHealthChecks.configuration.checks))
      if builder.overall_status == "ok"
        render plain: "OK", status: :ok
      else
        render plain: "Service Unavailable", status: :service_unavailable
      end
    end

    def group
      group_name = params[:group].to_sym
      check_names = RailsHealthChecks.configuration.groups[group_name]
      return render json: { error: "Group '#{group_name}' not found" }, status: :not_found unless check_names

      builder = ResponseBuilder.new(run_checks(check_names))
      render json: builder.to_json, status: builder.http_status
    end

    private

    def run_checks(check_names)
      config = RailsHealthChecks.configuration
      checks = CheckRegistry.build(check_names)
      CheckRegistry.run(checks, timeout: config.timeout)
    end
  end
end
