Vivi::Engine.routes.draw do
  get "docs/index"
  root :to => "docs#index"
  
  resources :docs
  match 'd/upload' => 'docs#new', :as => :doc_upload
  
end
