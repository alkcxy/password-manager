Rails.application.routes.draw do
  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  get 'welcome', to: 'sessions#welcome'
  delete 'logout', to: 'sessions#logout'
  resources :users
  resources :credentials do
    member do
      get :reveal_password
      get :hide_password
      get :copy_password
    end
  end
  root 'sessions#welcome'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
