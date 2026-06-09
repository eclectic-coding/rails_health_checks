# frozen_string_literal: true

module RailsHealthChecks
  class Engine < ::Rails::Engine
    isolate_namespace RailsHealthChecks
    config.generators.api_only = true

    config.after_initialize do
      RailsHealthChecks.configuration.validate!
    end
  end
end
