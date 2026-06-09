# frozen_string_literal: true

require "open3"

module RailsHealthChecks
  module Checks
    class MemoryCheck < Check
      def initialize(threshold: nil)
        @threshold = threshold
      end

      def call
        rss = nil
        measure { rss = rss_bytes }

        if @threshold && rss > @threshold
          return warn_with("process RSS #{rss} bytes exceeds threshold #{@threshold} bytes")
        end

        pass
      rescue StandardError => e
        fail_with(e.message)
      end

      private

      def rss_bytes
        out, _, status = Open3.capture3("ps", "-o", "rss=", "-p", Process.pid.to_s)
        raise "ps command failed with exit status #{status.exitstatus}" unless status.success?

        out.strip.to_i * 1024
      end
    end
  end
end
