module RailsHealthChecks
  class Engine < ::Rails::Engine
    isolate_namespace RailsHealthChecks
    config.generators.api_only = true
  end
end
