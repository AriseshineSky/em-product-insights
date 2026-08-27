Rails.application.routes.draw do
  # Dashboard
  root "dashboard#index"
  get "dashboard/products", to: "dashboard#products", as: :products

  # Tracked merchant product sources
  resources :merchant_sources, only: %i[index create destroy]

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
