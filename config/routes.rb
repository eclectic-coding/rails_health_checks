# frozen_string_literal: true

RailsHealthChecks::Engine.routes.draw do
  match "/",      to: "health#show",   as: :health,      via: [:get, :head]
  match "/live",  to: "live#show",     as: :health_live, via: [:get, :head]
  get "/metrics", to: "metrics#show",  as: :health_metrics
  get "/:id",     to: "groups#show",   as: :health_group
end
