# frozen_string_literal: true

module RailsHealthChecks
  class Configuration
    attr_accessor :checks, :timeout

    def initialize
      @checks = [:database]
      @timeout = 5
    end
  end
end
