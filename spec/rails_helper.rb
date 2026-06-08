# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require_relative 'dummy/config/environment'
require 'rspec/rails'

load Rails.root.join('db/schema.rb')

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
