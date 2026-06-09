# frozen_string_literal: true

module RailsHealthChecks
  module Checks
    class RedisCheck < Check
      def initialize(url: nil)
        unless defined?(::Redis)
          raise LoadError, "Redis is not installed. Add `gem 'redis'` to your Gemfile to use the :redis check."
        end

        @url = url
      end

      def call
        measure do
          client = ::Redis.new(url: @url || ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
          client.ping
          client.close
        end
        pass
      rescue StandardError => e
        fail_with(e.message)
      end
    end
  end
end
