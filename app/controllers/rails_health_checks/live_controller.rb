# frozen_string_literal: true

module RailsHealthChecks
  class LiveController < ApplicationController
    skip_before_action :authenticate!

    def show
      render plain: "OK", status: :ok
    end
  end
end
