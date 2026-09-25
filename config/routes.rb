Rails.application.routes.draw do
  root "sessions#new"

  resource :session, only: %i[new create destroy]
  resources :users, only: %i[new create]
  resource :dashboard, only: :show
  resources :groups, only: %i[new create show] do
    resources :memberships, only: :destroy
    resources :songs, only: %i[index create destroy]
    resources :rounds, only: :create
    resource :leaderboard, only: :show
    resources :activities, only: :index
  end
  resources :rounds, only: :show do
    post :finish, on: :member
    resources :guesses, only: :create
  end
  resource :join, only: %i[new create]
  resource :profile, only: %i[show edit update]
  resource :password, only: %i[edit update]
  get "email_confirmations/:token", to: "email_confirmations#show", as: :email_confirmation

  get "up" => "rails/health#show", as: :rails_health_check
end
