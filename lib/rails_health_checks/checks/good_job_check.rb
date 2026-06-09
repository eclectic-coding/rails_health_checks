# frozen_string_literal: true

module RailsHealthChecks
  module Checks
    class GoodJobCheck < Check
      def initialize(latency: nil)
        unless defined?(::GoodJob)
          raise LoadError, "GoodJob is not installed. Add `gem 'good_job'` to your Gemfile to use the :good_job check."
        end

        @latency = latency
      end

      def call
        measure do
          oldest = ::GoodJob::Job
            .where(finished_at: nil, performed_at: nil)
            .minimum(:created_at)

          if @latency && oldest
            age = (Time.current - oldest).to_i
            return warn_with("queue latency #{age}s exceeds threshold #{@latency}s") if age > @latency
          end
        end
        pass
      rescue StandardError => e
        fail_with(e.message)
      end
    end
  end
end
