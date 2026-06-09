# frozen_string_literal: true

require "rails/generators"

module RailsHealthChecks
  module Generators
    class InitializerGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates a RailsHealthChecks initializer with all available configuration options."

      def copy_initializer
        template "initializer.rb", "config/initializers/rails_health_checks.rb"
      end
    end
  end
end
