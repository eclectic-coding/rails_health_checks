# frozen_string_literal: true

RailsHealthChecks::Engine.routes.draw do
  get "/",       to: "health#show",  as: :health
  get "/live",   to: "health#live",  as: :health_live
  get "/:group", to: "health#group", as: :health_group
end
