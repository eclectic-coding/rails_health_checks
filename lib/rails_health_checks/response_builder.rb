# frozen_string_literal: true

module RailsHealthChecks
  class ResponseBuilder
    def initialize(results)
      @results = results
    end

    def overall_status
      statuses = @results.values.map(&:status)
      if statuses.include?('critical')
        'critical'
      elsif statuses.include?('degraded')
        'degraded'
      else
        'ok'
      end
    end

    def to_json(*)
      checks_hash = @results.transform_values do |check|
        result = { status: check.status }
        result[:latency_ms] = check.latency_ms if check.latency_ms
        result[:message] = check.message if check.message
        result
      end

      { status: overall_status, timestamp: Time.now.utc.iso8601, checks: checks_hash }.to_json
    end

    def http_status
      overall_status == 'ok' ? :ok : :service_unavailable
    end
  end
end
