Rails.application.routes.draw do
  root "sessions#new"

  resource :session, only: %i[new create destroy]
  resources :users, only: %i[new create]
  resource :dashboard, only: :show

  get "up" => "rails/health#show", as: :rails_health_check
end
