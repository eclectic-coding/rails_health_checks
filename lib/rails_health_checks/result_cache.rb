# frozen_string_literal: true

module RailsHealthChecks
  class ResultCache
    def initialize
      @store = {}
      @mutex = Mutex.new
    end

    def fetch(key, ttl:)
      @mutex.synchronize do
        entry = @store[key]
        return entry[:results] if entry && (Process.clock_gettime(Process::CLOCK_MONOTONIC) - entry[:at]) < ttl

        results = yield
        @store[key] = { results: results, at: Process.clock_gettime(Process::CLOCK_MONOTONIC) }
        results
      end
    end

    def clear
      @mutex.synchronize { @store.clear }
    end
  end
end
