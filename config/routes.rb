Rails.application.routes.draw do
  devise_for :users,
    path: "auth",
    path_names: {
      sign_in: "login",
      sign_out: "logout",
      registration: "signup"
    },
    controllers: {
      sessions: "auth/sessions",
      registrations: "auth/registrations",
      passwords: "auth/passwords",
      confirmations: "auth/confirmations"
    }

  # Two-factor authentication
  namespace :auth do
    post "verify-2fa", to: "two_factor#verify"
    post "setup-2fa", to: "two_factor#setup"
  end

  # Internal (authenticated user) endpoints
  namespace :internal do
    resource :me, only: [ :show ], controller: "me"
    resource :settings, only: [ :show ] do
      patch :locale
    end
  end

  # Admin endpoints
  namespace :admin do
    get "facts_datasets/live", to: "facts_datasets#live"
    get "facts_datasets/draft", to: "facts_datasets#draft"
    post "facts_datasets/draft", to: "facts_datasets#create_draft"
    patch "facts_datasets/draft", to: "facts_datasets#update_draft"
    delete "facts_datasets/draft", to: "facts_datasets#delete_draft"
    post "facts_datasets/draft/publish", to: "facts_datasets#publish_draft"

    resources :actions, only: [ :index, :show, :create, :update ]
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
