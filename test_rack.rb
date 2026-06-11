# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("lib")
require "rails_health_checks"
require "rails_health_checks/rack/app"

RailsHealthChecks.configure do |config|
  config.checks = [:disk, :memory]
end

browser = Rack::MockRequest.new(RailsHealthChecks::Rack::App)

%w[/ /live /metrics /nonexistent].each do |path|
  res = browser.get(path)
  puts "GET #{path} => #{res.status}  #{res.body[0, 120]}"
end
