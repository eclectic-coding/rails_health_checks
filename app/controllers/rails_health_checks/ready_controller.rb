# frozen_string_literal: true

module RailsHealthChecks
  class ReadyController < ApplicationController
    def show
      builder = ResponseBuilder.new(run_checks(RailsHealthChecks.configuration.checks))
      if builder.overall_status == "ok"
        render plain: "OK", status: :ok
      else
        render plain: "Service Unavailable", status: :service_unavailable
      end
    end
  end
end
