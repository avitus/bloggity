Rails.application.routes.draw do
  resources :users, only: [:show]
  mount Bloggity::Engine => "/bloggity"
end
