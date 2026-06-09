# frozen_string_literal: true

module RailsHealthChecks
  class ApplicationController < ActionController::API
    include Authentication
    before_action :authenticate!
  end
end
