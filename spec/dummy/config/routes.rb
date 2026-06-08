Rails.application.routes.draw do
  mount RailsHealthChecks::Engine => '/health'
end
