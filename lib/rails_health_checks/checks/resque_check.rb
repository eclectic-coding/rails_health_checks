# frozen_string_literal: true

module RailsHealthChecks
  module Checks
    class ResqueCheck < Check
      def initialize(queue_size: nil)
        unless defined?(::Resque)
          raise LoadError, "Resque is not installed. Add `gem 'resque'` to your Gemfile to use the :resque check."
        end

        @queue_size = queue_size
      end

      def call
        measure { ::Resque.redis.ping }

        if @queue_size
          depth = ::Resque.queues.sum { |q| ::Resque.size(q) }
          return warn_with("queue depth #{depth} exceeds threshold #{@queue_size}") if depth > @queue_size
        end

        pass
      rescue StandardError => e
        fail_with(e.message)
      end
    end
  end
end
