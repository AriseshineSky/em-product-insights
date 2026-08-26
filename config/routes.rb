Rails.application.routes.draw do
  # Dashboard
  root "dashboard#index"
  get "dashboard/products", to: "dashboard#products", as: :products

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
