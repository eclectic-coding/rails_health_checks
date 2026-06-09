# frozen_string_literal: true

module RailsHealthChecks
  class MetricsController < ApplicationController
    def show
      results = run_checks(RailsHealthChecks.configuration.checks)
      render plain: PrometheusFormatter.new(results).to_text,
             content_type: "text/plain; version=0.0.4",
             status: :ok
    end
  end
end
