# frozen_string_literal: true

module RailsHealthChecks
  class HealthController < ApplicationController
    def show
      builder = ResponseBuilder.new(run_checks(RailsHealthChecks.configuration.checks))
      render json: builder.to_json, status: builder.http_status
    end
  end
end
