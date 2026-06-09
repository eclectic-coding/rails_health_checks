require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)
require 'rails_health_checks'

module Dummy
  class Application < Rails::Application
    config.load_defaults 8.1
    config.eager_load = false
    config.cache_store = :memory_store
  end
end