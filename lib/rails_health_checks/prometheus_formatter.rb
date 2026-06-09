# frozen_string_literal: true

module RailsHealthChecks
  class PrometheusFormatter
    STATUS_CODES = { "ok" => 0, "degraded" => 1, "critical" => 2 }.freeze

    def initialize(results)
      @results = results
    end

    def to_text
      lines = []

      lines << "# HELP rails_health_check_status Health check status (0=ok, 1=degraded, 2=critical)"
      lines << "# TYPE rails_health_check_status gauge"
      @results.each { |name, check| lines << "rails_health_check_status{check=\"#{name}\"} #{STATUS_CODES[check.status]}" }

      lines << ""
      lines << "# HELP rails_health_check_latency_ms Health check latency in milliseconds"
      lines << "# TYPE rails_health_check_latency_ms gauge"
      @results.each do |name, check|
        lines << "rails_health_check_latency_ms{check=\"#{name}\"} #{check.latency_ms}" if check.latency_ms
      end

      lines.join("\n") + "\n"
    end
  end
end
