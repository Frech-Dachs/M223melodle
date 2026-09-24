Rails.application.routes.draw do
  root "sessions#new"

  resource :session, only: %i[new create destroy]
  resources :users, only: %i[new create]
  resource :dashboard, only: :show
  resource :profile, only: %i[show edit update]
  resource :password, only: %i[edit update]
  get "email_confirmations/:token", to: "email_confirmations#show", as: :email_confirmation

  get "up" => "rails/health#show", as: :rails_health_check
end
