# frozen_string_literal: true

module RailsHealthChecks
  module Checks
    class DatabaseCheck < Check
      def call
        measure { ActiveRecord::Base.connection.execute("SELECT 1") }
        pass
      rescue StandardError => e
        fail_with(e.message)
      end
    end
  end
end
