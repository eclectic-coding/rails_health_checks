# frozen_string_literal: true

require "open3"

module RailsHealthChecks
  module Checks
    class DiskCheck < Check
      def initialize(warn_threshold: nil, critical_threshold: nil, path: "/")
        @warn_threshold = warn_threshold
        @critical_threshold = critical_threshold
        @path = path
      end

      def call
        free = nil
        measure { free = free_bytes }

        if @critical_threshold && free < @critical_threshold
          return fail_with("free disk space #{free} bytes below critical threshold #{@critical_threshold} bytes")
        end

        if @warn_threshold && free < @warn_threshold
          return warn_with("free disk space #{free} bytes below warn threshold #{@warn_threshold} bytes")
        end

        pass
      rescue StandardError => e
        fail_with(e.message)
      end

      private

      def free_bytes
        out, _, status = Open3.capture3("df", "-Pk", @path.to_s)
        raise "df command failed with exit status #{status.exitstatus}" unless status.success?

        parts = out.split("\n").last.split
        parts[3].to_i * 1024
      end
    end
  end
end
