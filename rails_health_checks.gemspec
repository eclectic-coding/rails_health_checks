require_relative "lib/rails_health_checks/version"

Gem::Specification.new do |spec|
  spec.name        = "rails_health_checks"
  spec.version     = RailsHealthChecks::VERSION
  spec.authors     = [ "Chuck Smith" ]
  spec.email       = [ "chuck@eclecticcoding.com" ]
  spec.homepage    = "https://github.com/eclectic-coding/rails_health_checks"
  spec.summary     = "Health check endpoints for Rails applications."
  spec.description = "A Rails engine that provides configurable health check endpoints for monitoring application status."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/eclectic-coding/rails_health_checks"
  spec.metadata["changelog_uri"] = "https://github.com/eclectic-coding/rails_health_checks/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.1.3"

  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'factory_bot_rails'
  spec.add_development_dependency 'rubocop-rails'
  spec.add_development_dependency 'simplecov'
end
