Bloggity::Engine.routes.draw do

	root :to => "blog_posts#index"

	resources :blogs do

	resources :blog_posts do     
	  
	collection do
		get :pending
		post :create_asset
	end

	member do
		get :close
	end

	end

	member do
		get :feed
	end

	end	
	
	resources :blog_categories
	resources :blog_assets
	resources :blog_comments, :member => { :approve => :get }


	# Blog routes
	match '/blog_comments_new',      :to => 'blog_comments#recent_comments',                   :as => 'blog_comments_new'
	match '/blog_search',            :to => 'blog_posts#blog_search',                          :as => 'blog_search'

	match  ':blog_url_id_or_id',     :to => 'blog_posts#index'
	match  ':blog_url_id_or_id/:id', :to => 'blog_posts#show'
	match  'blog',                        :to => 'blog_posts#index', :as => 'blog', :blog_url_id_or_id => 'main'



end
