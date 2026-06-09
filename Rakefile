# frozen_string_literal: true

require 'bundler/setup'

require 'bundler/gem_tasks'
require 'rubocop/rake_task'
require 'bundler/audit/task'
require 'rspec/core/rake_task'

RuboCop::RakeTask.new(:lint)
Bundler::Audit::Task.new
RSpec::Core::RakeTask.new(:spec)

task default: [:lint, :'bundle:audit:update', 'bundle:audit:check', :spec]

desc "Run performance benchmarks"
task :benchmark do
  ruby "benchmarks/benchmark.rb"
end
