# frozen_string_literal: true

require "rails_health_checks/version"
require "rails_health_checks/engine"
require "rails_health_checks/configuration"
require "rails_health_checks/authentication"
require "rails_health_checks/check"
require "rails_health_checks/checks/database_check"
require "rails_health_checks/checks/cache_check"
require "rails_health_checks/checks/sidekiq_check"
require "rails_health_checks/checks/solid_queue_check"
require "rails_health_checks/checks/good_job_check"
require "rails_health_checks/checks/resque_check"
require "rails_health_checks/checks/disk_check"
require "rails_health_checks/checks/memory_check"
require "rails_health_checks/checks/http_check"
require "rails_health_checks/check_registry"
require "rails_health_checks/response_builder"
require "rails_health_checks/prometheus_formatter"

module RailsHealthChecks
  class << self
    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end
  end
end
