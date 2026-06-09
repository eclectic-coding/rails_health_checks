# frozen_string_literal: true

RailsHealthChecks::Engine.routes.draw do
  get "/",        to: "health#show",   as: :health
  get "/live",    to: "live#show",     as: :health_live
  get "/metrics", to: "metrics#show",  as: :health_metrics
  get "/:id",     to: "groups#show",   as: :health_group
end
