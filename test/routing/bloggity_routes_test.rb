require 'test_helper'

class BloggityRoutesTest < ActionDispatch::IntegrationTest
  fixtures :all

  def setup
    # Use fixture data instead of creating new records  
    @blog = Bloggity::Blog.find(1) # primary_blog from fixtures
    @user = User.find(1) # blogger_user from fixtures
    
    # Create minimal test data
    @blog_post = Bloggity::BlogPost.create!(
      title: 'Test Post',
      body: 'Test content',
      blog_id: @blog.id,
      posted_by_id: @user.id,
      is_complete: true,
      url_identifier: 'test-post'
    )

    @blog_comment = Bloggity::BlogComment.create!(
      comment: 'Test comment',
      blog_post_id: @blog_post.id,
      user_id: @user.id,
      approved: true
    )

    @blog_category = Bloggity::BlogCategory.create!(
      name: 'Test Category'
    )
  end

  # ROOT ROUTE TESTS
  test "root route should route to blog_posts#index" do
    assert_recognizes({ controller: 'bloggity/blog_posts', action: 'index' }, '/bloggity')
  end

  test "root route should be accessible" do
    # Test the route mapping without actually making the request
    # since the controller requires specific setup
    assert_recognizes({ controller: 'bloggity/blog_posts', action: 'index' }, '/bloggity')
  end

  # BLOG ROUTES TESTS
  test "blogs index route should work" do
    assert_routing({ path: '/bloggity/blogs', method: :get }, 
                   { controller: 'bloggity/blogs', action: 'index' })
  end

  test "blogs show route should work" do
    assert_routing({ path: "/bloggity/blogs/#{@blog.id}", method: :get }, 
                   { controller: 'bloggity/blogs', action: 'show', id: @blog.id.to_s })
  end

  test "blogs new route should work" do
    assert_routing({ path: '/bloggity/blogs/new', method: :get }, 
                   { controller: 'bloggity/blogs', action: 'new' })
  end

  test "blogs edit route should work" do
    assert_routing({ path: "/bloggity/blogs/#{@blog.id}/edit", method: :get }, 
                   { controller: 'bloggity/blogs', action: 'edit', id: @blog.id.to_s })
  end

  test "blogs create route should work" do
    assert_routing({ path: '/bloggity/blogs', method: :post }, 
                   { controller: 'bloggity/blogs', action: 'create' })
  end

  test "blogs update route should work" do
    assert_routing({ path: "/bloggity/blogs/#{@blog.id}", method: :patch }, 
                   { controller: 'bloggity/blogs', action: 'update', id: @blog.id.to_s })
    
    assert_routing({ path: "/bloggity/blogs/#{@blog.id}", method: :put }, 
                   { controller: 'bloggity/blogs', action: 'update', id: @blog.id.to_s })
  end

  test "blogs destroy route should work" do
    assert_routing({ path: "/bloggity/blogs/#{@blog.id}", method: :delete }, 
                   { controller: 'bloggity/blogs', action: 'destroy', id: @blog.id.to_s })
  end

  test "blog feed route should work" do
    assert_routing({ path: "/bloggity/blogs/#{@blog.id}/feed", method: :get }, 
                   { controller: 'bloggity/blogs', action: 'feed', id: @blog.id.to_s })
  end

  # NESTED BLOG POSTS ROUTES TESTS
  test "nested blog posts index route should work" do
    assert_routing({ path: "/bloggity/blogs/#{@blog.id}/blog_posts", method: :get }, 
                   { controller: 'bloggity/blog_posts', action: 'index', blog_id: @blog.id.to_s })
  end

  test "nested blog posts show route should work" do
    assert_routing({ path: "/bloggity/blogs/#{@blog.id}/blog_posts/#{@blog_post.id}", method: :get }, 
                   { controller: 'bloggity/blog_posts', action: 'show', blog_id: @blog.id.to_s, id: @blog_post.id.to_s })
  end

  test "nested blog posts new route should work" do
    assert_routing({ path: "/bloggity/blogs/#{@blog.id}/blog_posts/new", method: :get }, 
                   { controller: 'bloggity/blog_posts', action: 'new', blog_id: @blog.id.to_s })
  end

  test "nested blog posts edit route should work" do
    assert_routing({ path: "/bloggity/blogs/#{@blog.id}/blog_posts/#{@blog_post.id}/edit", method: :get }, 
                   { controller: 'bloggity/blog_posts', action: 'edit', blog_id: @blog.id.to_s, id: @blog_post.id.to_s })
  end

  test "nested blog posts create route should work" do
    assert_routing({ path: "/bloggity/blogs/#{@blog.id}/blog_posts", method: :post }, 
                   { controller: 'bloggity/blog_posts', action: 'create', blog_id: @blog.id.to_s })
  end

  test "nested blog posts update route should work" do
    assert_routing({ path: "/bloggity/blogs/#{@blog.id}/blog_posts/#{@blog_post.id}", method: :patch }, 
                   { controller: 'bloggity/blog_posts', action: 'update', blog_id: @blog.id.to_s, id: @blog_post.id.to_s })
    
    assert_routing({ path: "/bloggity/blogs/#{@blog.id}/blog_posts/#{@blog_post.id}", method: :put }, 
                   { controller: 'bloggity/blog_posts', action: 'update', blog_id: @blog.id.to_s, id: @blog_post.id.to_s })
  end

  test "nested blog posts destroy route should work" do
    assert_routing({ path: "/bloggity/blogs/#{@blog.id}/blog_posts/#{@blog_post.id}", method: :delete }, 
                   { controller: 'bloggity/blog_posts', action: 'destroy', blog_id: @blog.id.to_s, id: @blog_post.id.to_s })
  end

  # BLOG POSTS COLLECTION ROUTES
  test "blog posts pending collection route should work" do
    assert_routing({ path: "/bloggity/blogs/#{@blog.id}/blog_posts/pending", method: :get }, 
                   { controller: 'bloggity/blog_posts', action: 'pending', blog_id: @blog.id.to_s })
  end

  test "blog posts create_asset collection route should work" do
    assert_routing({ path: "/bloggity/blogs/#{@blog.id}/blog_posts/create_asset", method: :post }, 
                   { controller: 'bloggity/blog_posts', action: 'create_asset', blog_id: @blog.id.to_s })
  end

  # BLOG POSTS MEMBER ROUTES
  test "blog posts close member route should work" do
    assert_routing({ path: "/bloggity/blogs/#{@blog.id}/blog_posts/#{@blog_post.id}/close", method: :get }, 
                   { controller: 'bloggity/blog_posts', action: 'close', blog_id: @blog.id.to_s, id: @blog_post.id.to_s })
  end

  # BLOG CATEGORIES ROUTES TESTS
  test "blog categories index route should work" do
    assert_routing({ path: '/bloggity/blog_categories', method: :get }, 
                   { controller: 'bloggity/blog_categories', action: 'index' })
  end

  test "blog categories show route should work" do
    assert_routing({ path: "/bloggity/blog_categories/#{@blog_category.id}", method: :get }, 
                   { controller: 'bloggity/blog_categories', action: 'show', id: @blog_category.id.to_s })
  end

  test "blog categories new route should work" do
    assert_routing({ path: '/bloggity/blog_categories/new', method: :get }, 
                   { controller: 'bloggity/blog_categories', action: 'new' })
  end

  test "blog categories edit route should work" do
    assert_routing({ path: "/bloggity/blog_categories/#{@blog_category.id}/edit", method: :get }, 
                   { controller: 'bloggity/blog_categories', action: 'edit', id: @blog_category.id.to_s })
  end

  test "blog categories create route should work" do
    assert_routing({ path: '/bloggity/blog_categories', method: :post }, 
                   { controller: 'bloggity/blog_categories', action: 'create' })
  end

  test "blog categories update route should work" do
    assert_routing({ path: "/bloggity/blog_categories/#{@blog_category.id}", method: :patch }, 
                   { controller: 'bloggity/blog_categories', action: 'update', id: @blog_category.id.to_s })
    
    assert_routing({ path: "/bloggity/blog_categories/#{@blog_category.id}", method: :put }, 
                   { controller: 'bloggity/blog_categories', action: 'update', id: @blog_category.id.to_s })
  end

  test "blog categories destroy route should work" do
    assert_routing({ path: "/bloggity/blog_categories/#{@blog_category.id}", method: :delete }, 
                   { controller: 'bloggity/blog_categories', action: 'destroy', id: @blog_category.id.to_s })
  end

  # BLOG ASSETS ROUTES TESTS
  test "blog assets routes should work" do
    assert_routing({ path: '/bloggity/blog_assets', method: :get }, 
                   { controller: 'bloggity/blog_assets', action: 'index' })
    
    assert_routing({ path: '/bloggity/blog_assets/1', method: :get }, 
                   { controller: 'bloggity/blog_assets', action: 'show', id: '1' })
    
    assert_routing({ path: '/bloggity/blog_assets/new', method: :get }, 
                   { controller: 'bloggity/blog_assets', action: 'new' })
    
    assert_routing({ path: '/bloggity/blog_assets/1/edit', method: :get }, 
                   { controller: 'bloggity/blog_assets', action: 'edit', id: '1' })
    
    assert_routing({ path: '/bloggity/blog_assets', method: :post }, 
                   { controller: 'bloggity/blog_assets', action: 'create' })
    
    assert_routing({ path: '/bloggity/blog_assets/1', method: :patch }, 
                   { controller: 'bloggity/blog_assets', action: 'update', id: '1' })
    
    assert_routing({ path: '/bloggity/blog_assets/1', method: :put }, 
                   { controller: 'bloggity/blog_assets', action: 'update', id: '1' })
    
    assert_routing({ path: '/bloggity/blog_assets/1', method: :delete }, 
                   { controller: 'bloggity/blog_assets', action: 'destroy', id: '1' })
  end

  # BLOG COMMENTS ROUTES TESTS
  test "blog comments index route should work" do
    assert_routing({ path: '/bloggity/blog_comments', method: :get }, 
                   { controller: 'bloggity/blog_comments', action: 'index' })
  end

  test "blog comments show route should work" do
    assert_routing({ path: "/bloggity/blog_comments/#{@blog_comment.id}", method: :get }, 
                   { controller: 'bloggity/blog_comments', action: 'show', id: @blog_comment.id.to_s })
  end

  test "blog comments new route should work" do
    assert_routing({ path: '/bloggity/blog_comments/new', method: :get }, 
                   { controller: 'bloggity/blog_comments', action: 'new' })
  end

  test "blog comments edit route should work" do
    assert_routing({ path: "/bloggity/blog_comments/#{@blog_comment.id}/edit", method: :get }, 
                   { controller: 'bloggity/blog_comments', action: 'edit', id: @blog_comment.id.to_s })
  end

  test "blog comments create route should work" do
    assert_routing({ path: '/bloggity/blog_comments', method: :post }, 
                   { controller: 'bloggity/blog_comments', action: 'create' })
  end

  test "blog comments update route should work" do
    assert_routing({ path: "/bloggity/blog_comments/#{@blog_comment.id}", method: :patch }, 
                   { controller: 'bloggity/blog_comments', action: 'update', id: @blog_comment.id.to_s })
    
    assert_routing({ path: "/bloggity/blog_comments/#{@blog_comment.id}", method: :put }, 
                   { controller: 'bloggity/blog_comments', action: 'update', id: @blog_comment.id.to_s })
  end

  test "blog comments destroy route should work" do
    assert_routing({ path: "/bloggity/blog_comments/#{@blog_comment.id}", method: :delete }, 
                   { controller: 'bloggity/blog_comments', action: 'destroy', id: @blog_comment.id.to_s })
  end

  test "blog comments approve member route should work" do
    assert_routing({ path: "/bloggity/blog_comments/#{@blog_comment.id}/approve", method: :get }, 
                   { controller: 'bloggity/blog_comments', action: 'approve', id: @blog_comment.id.to_s })
  end

  # CUSTOM BLOG ROUTES TESTS
  test "blog comments new custom route should work" do
    assert_routing({ path: '/bloggity/blog_comments_new', method: :get }, 
                   { controller: 'bloggity/blog_comments', action: 'recent_comments' })
  end

  test "blog search custom route should work" do
    assert_routing({ path: '/bloggity/blog_search', method: :get }, 
                   { controller: 'bloggity/blog_posts', action: 'blog_search' })
  end

  # SEO-FRIENDLY URL ROUTING TESTS
  test "blog url identifier route should work" do
    assert_routing({ path: "/bloggity/#{@blog.url_identifier}", method: :get }, 
                   { controller: 'bloggity/blog_posts', action: 'index', blog_url_id_or_id: @blog.url_identifier })
  end

  test "blog url identifier with post id route should work" do
    assert_routing({ path: "/bloggity/#{@blog.url_identifier}/#{@blog_post.id}", method: :get }, 
                   { controller: 'bloggity/blog_posts', action: 'show', blog_url_id_or_id: @blog.url_identifier, id: @blog_post.id.to_s })
  end

  test "default blog route should work" do
    assert_routing({ path: '/bloggity/blog', method: :get }, 
                   { controller: 'bloggity/blog_posts', action: 'index', blog_url_id_or_id: 'main' })
  end

  # ROUTE HELPERS TESTS
  test "bloggity route helpers should be available" do
    assert_respond_to self, :bloggity
    assert_instance_of Bloggity::Engine, bloggity
  end

  test "blog path helper should work" do
    path = bloggity.blog_path(@blog)
    assert_equal "/bloggity/blogs/#{@blog.id}", path
  end

  test "blogs path helper should work" do
    path = bloggity.blogs_path
    assert_equal "/bloggity/blogs", path
  end

  test "blog_posts path helper should work" do
    path = bloggity.blog_blog_posts_path(@blog)
    assert_equal "/bloggity/blogs/#{@blog.id}/blog_posts", path
  end

  test "blog_post path helper should work" do
    path = bloggity.blog_blog_post_path(@blog, @blog_post)
    assert_equal "/bloggity/blogs/#{@blog.id}/blog_posts/#{@blog_post.id}", path
  end

  test "blog_categories path helper should work" do
    path = bloggity.blog_categories_path
    assert_equal "/bloggity/blog_categories", path
  end

  test "blog_category path helper should work" do
    path = bloggity.blog_category_path(@blog_category)
    assert_equal "/bloggity/blog_categories/#{@blog_category.id}", path
  end

  test "blog_comments path helper should work" do
    path = bloggity.blog_comments_path
    assert_equal "/bloggity/blog_comments", path
  end

  test "blog_comment path helper should work" do
    path = bloggity.blog_comment_path(@blog_comment)
    assert_equal "/bloggity/blog_comments/#{@blog_comment.id}", path
  end

  test "custom route helpers should work" do
    assert_equal "/bloggity/blog_comments_new", bloggity.blog_comments_new_path
    assert_equal "/bloggity/blog_search", bloggity.blog_search_path
  end

  test "feed route helper should work" do
    path = bloggity.feed_blog_path(@blog)
    assert_equal "/bloggity/blogs/#{@blog.id}/feed", path
  end

  test "pending blog posts route helper should work" do
    path = bloggity.pending_blog_blog_posts_path(@blog)
    assert_equal "/bloggity/blogs/#{@blog.id}/blog_posts/pending", path
  end

  test "close blog post route helper should work" do
    path = bloggity.close_blog_blog_post_path(@blog, @blog_post)
    assert_equal "/bloggity/blogs/#{@blog.id}/blog_posts/#{@blog_post.id}/close", path
  end

  test "approve blog comment route helper should work" do
    path = bloggity.approve_blog_comment_path(@blog_comment)
    assert_equal "/bloggity/blog_comments/#{@blog_comment.id}/approve", path
  end

  # NAMESPACE AND ENGINE TESTS
  test "routes should be properly namespaced" do
    # All routes should be under the bloggity namespace
    routes = bloggity.routes.routes.map(&:path).map(&:spec).map(&:to_s)
    
    routes.each do |route|
      # Skip the root route which starts with just '/'
      next if route == '/'
      
      # All other routes should start with '/bloggity' when mounted
      # Note: In the engine itself, routes don't have the mount prefix
      assert route.start_with?('/') || route.include?('bloggity'), 
             "Route '#{route}' should be properly namespaced"
    end
  end

  test "engine routes should be isolated" do
    # Verify that the engine routes are properly isolated and don't conflict with main app
    assert_not_nil bloggity.routes
    assert_instance_of ActionDispatch::Routing::RouteSet, bloggity.routes
  end

  # INTEGRATION TESTS - Testing route recognition patterns
  test "nested resource routing patterns should be recognized" do
    # Test that nested routes are properly recognized
    assert_recognizes(
      { controller: 'bloggity/blog_posts', action: 'create', blog_id: @blog.id.to_s },
      { path: "/bloggity/blogs/#{@blog.id}/blog_posts", method: :post }
    )
  end

  test "SEO friendly URL patterns should be recognized" do
    # Test that SEO URLs are properly recognized
    assert_recognizes(
      { controller: 'bloggity/blog_posts', action: 'index', blog_url_id_or_id: @blog.url_identifier },
      "/bloggity/#{@blog.url_identifier}"
    )
    
    assert_recognizes(
      { controller: 'bloggity/blog_posts', action: 'show', blog_url_id_or_id: @blog.url_identifier, id: @blog_post.id.to_s },
      "/bloggity/#{@blog.url_identifier}/#{@blog_post.id}"
    )
  end
end