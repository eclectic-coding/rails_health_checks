require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)
require 'rails_health_checks'

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::MAJOR >= 8 ? 8.0 : 7.1
    config.eager_load = false
    config.cache_store = :memory_store
  end
end