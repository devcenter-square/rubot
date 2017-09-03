Rails.application.routes.draw do
  resources :blasts
  resources :logs
  resources :interactions
  devise_for :admins, :controllers => { :omniauth_callbacks => "callbacks" }
  resources :messages
  resources :users
  resources :metrics
  post 'users/status'
  get 'healthcheck' => 'healthchecks#check'

  root to: "home#index"
end
