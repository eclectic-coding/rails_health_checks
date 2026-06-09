# frozen_string_literal: true

module RailsHealthChecks
  module Checks
    class SolidQueueCheck < Check
      def initialize(job_count: nil)
        unless defined?(::SolidQueue)
          raise LoadError, "SolidQueue is not installed. Add `gem 'solid_queue'` to your Gemfile to use the :solid_queue check."
        end

        @job_count = job_count
      end

      def call
        measure do
          pending = ::SolidQueue::ReadyExecution.count
          if @job_count && pending > @job_count
            return warn_with("pending job count #{pending} exceeds threshold #{@job_count}")
          end
        end
        pass
      rescue StandardError => e
        fail_with(e.message)
      end
    end
  end
end
