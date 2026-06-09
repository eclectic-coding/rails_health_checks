# frozen_string_literal: true

module RailsHealthChecks
  module Checks
    class SidekiqCheck < Check
      def initialize(queue_size: nil)
        unless defined?(::Sidekiq)
          raise LoadError, "Sidekiq is not installed. Add `gem 'sidekiq'` to your Gemfile to use the :sidekiq check."
        end

        @queue_size = queue_size
      end

      def call
        measure { ::Sidekiq.redis { |conn| conn.ping } }

        if @queue_size
          depth = ::Sidekiq::Queue.all.sum(&:size)
          return warn_with("queue depth #{depth} exceeds threshold #{@queue_size}") if depth > @queue_size
        end

        pass
      rescue StandardError => e
        fail_with(e.message)
      end
    end
  end
end
