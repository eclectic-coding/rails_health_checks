# frozen_string_literal: true

module RailsHealthChecks
  class Check
    attr_reader :status, :message, :latency_ms

    def call
      raise NotImplementedError, "#{self.class} must implement #call"
    end

    private

    def pass(message = nil)
      @status = 'ok'
      @message = message
    end

    def warn_with(message)
      @status = 'degraded'
      @message = message
    end

    def fail_with(message)
      @status = 'critical'
      @message = message
    end

    def measure
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      yield
      @latency_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round
    end
  end
end
