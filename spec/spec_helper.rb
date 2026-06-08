# frozen_string_literal: true

require 'simplecov'
require 'simplecov-json'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
                                                                 SimpleCov::Formatter::HTMLFormatter,
                                                                 SimpleCov::Formatter::JSONFormatter
                                                               ])

SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/lib/rails_health_checks/version.rb'

  add_group 'Controllers', 'app/controllers'
  add_group 'Library',     'lib'
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random
  Kernel.srand config.seed
end
