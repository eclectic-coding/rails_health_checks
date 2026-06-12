# frozen_string_literal: true

RailsHealthChecks::Engine.routes.draw do
  readiness_path = RailsHealthChecks.configuration.readiness_path

  match "/",                    to: "health#show",   as: :health,          via: [:get, :head]
  match "/live",                to: "live#show",     as: :health_live,     via: [:get, :head]
  match "/#{readiness_path}",   to: "ready#show",    as: :health_ready,    via: [:get, :head]
  get "/metrics",               to: "metrics#show",  as: :health_metrics
  get "/:id",                   to: "groups#show",   as: :health_group
end
