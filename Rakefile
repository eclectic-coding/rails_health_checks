# frozen_string_literal: true

require 'bundler/setup'

require 'bundler/gem_tasks'
require 'rubocop/rake_task'
require 'bundler/audit/task'
require 'rspec/core/rake_task'

RuboCop::RakeTask.new(:lint)
Bundler::Audit::Task.new
RSpec::Core::RakeTask.new(:spec)

desc "Run Brakeman static security analysis"
task :brakeman do
  sh "bundle exec brakeman -q --no-pager --force-scan --skip-files spec/ ."
end

task default: [:lint, :'bundle:audit:update', 'bundle:audit:check', :brakeman, :spec]

desc "Run performance benchmarks"
task :benchmark do
  ruby "benchmarks/benchmark.rb"
end
