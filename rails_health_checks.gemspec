# frozen_string_literal: true

require_relative 'lib/rails_health_checks/version'

Gem::Specification.new do |spec|
  spec.name        = 'rails_health_checks'
  spec.version     = RailsHealthChecks::VERSION
  spec.authors     = ['Chuck Smith']
  spec.email       = ['chuck@eclecticcoding.com']
  spec.homepage    = 'https://github.com/eclectic-coding/rails_health_checks'
  spec.summary     = 'Production-grade health check endpoints for Rails applications.'
  spec.description = 'A Rails engine that adds structured, pluggable health check endpoints to any Rails app. ' \
                     'Includes 11 built-in checks (database, cache, Redis, SMTP, Sidekiq, SolidQueue, GoodJob, ' \
                     'Resque, disk, memory, HTTP), parallel execution via Concurrent::Future, result caching, ' \
                     'Prometheus metrics, check groups, per-environment toggling, boot-time validation, ' \
                     'and a Prometheus-compatible /metrics endpoint. Drop-in replacement for OkComputer.'
  spec.license     = 'MIT'
  spec.required_ruby_version = '>= 3.3'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/eclectic-coding/rails_health_checks'
  spec.metadata['changelog_uri'] = 'https://github.com/eclectic-coding/rails_health_checks/blob/main/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  end

  spec.add_dependency 'rails', '>= 7.1'
  spec.add_dependency 'concurrent-ruby', '>= 1.1'
end
