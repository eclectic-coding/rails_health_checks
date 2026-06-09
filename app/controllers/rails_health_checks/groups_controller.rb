# frozen_string_literal: true

module RailsHealthChecks
  class GroupsController < ApplicationController
    def show
      group_name = params[:id].to_sym
      check_names = RailsHealthChecks.configuration.groups[group_name]
      return render json: { error: "Group '#{group_name}' not found" }, status: :not_found unless check_names

      builder = ResponseBuilder.new(run_checks(check_names))
      render json: builder.to_json, status: builder.http_status
    end
  end
end
