require 'test_helper'

class BloggityRoutesSimpleTest < ActionDispatch::IntegrationTest
  # Simple routing tests that focus on route recognition without HTTP requests
  
  # ROOT ROUTE TESTS
  test "root route should be recognized" do
    assert_recognizes(
      { controller: 'bloggity/blog_posts', action: 'index' }, 
      '/bloggity'
    )
  end

  # BLOG ROUTES TESTS
  test "blogs resource routes should be recognized" do
    assert_recognizes(
      { controller: 'bloggity/blogs', action: 'index' },
      '/bloggity/blogs'
    )
    
    assert_recognizes(
      { controller: 'bloggity/blogs', action: 'show', id: '1' },
      '/bloggity/blogs/1'
    )
    
    assert_recognizes(
      { controller: 'bloggity/blogs', action: 'new' },
      '/bloggity/blogs/new'
    )
    
    assert_recognizes(
      { controller: 'bloggity/blogs', action: 'edit', id: '1' },
      '/bloggity/blogs/1/edit'
    )
  end

  test "blog feed route should be recognized" do
    assert_recognizes(
      { controller: 'bloggity/blogs', action: 'feed', id: '1' },
      '/bloggity/blogs/1/feed'
    )
  end

  # NESTED BLOG POSTS ROUTES
  test "nested blog posts routes should be recognized" do
    assert_recognizes(
      { controller: 'bloggity/blog_posts', action: 'index', blog_id: '1' },
      '/bloggity/blogs/1/blog_posts'
    )
    
    assert_recognizes(
      { controller: 'bloggity/blog_posts', action: 'show', blog_id: '1', id: '2' },
      '/bloggity/blogs/1/blog_posts/2'
    )
    
    assert_recognizes(
      { controller: 'bloggity/blog_posts', action: 'new', blog_id: '1' },
      '/bloggity/blogs/1/blog_posts/new'
    )
    
    assert_recognizes(
      { controller: 'bloggity/blog_posts', action: 'edit', blog_id: '1', id: '2' },
      '/bloggity/blogs/1/blog_posts/2/edit'
    )
  end

  test "blog posts collection routes should be recognized" do
    assert_recognizes(
      { controller: 'bloggity/blog_posts', action: 'pending', blog_id: '1' },
      '/bloggity/blogs/1/blog_posts/pending'
    )
  end

  test "blog posts member routes should be recognized" do
    assert_recognizes(
      { controller: 'bloggity/blog_posts', action: 'close', blog_id: '1', id: '2' },
      '/bloggity/blogs/1/blog_posts/2/close'
    )
  end

  # BLOG CATEGORIES ROUTES
  test "blog categories routes should be recognized" do
    assert_recognizes(
      { controller: 'bloggity/blog_categories', action: 'index' },
      '/bloggity/blog_categories'
    )
    
    assert_recognizes(
      { controller: 'bloggity/blog_categories', action: 'show', id: '1' },
      '/bloggity/blog_categories/1'
    )
    
    assert_recognizes(
      { controller: 'bloggity/blog_categories', action: 'new' },
      '/bloggity/blog_categories/new'
    )
    
    assert_recognizes(
      { controller: 'bloggity/blog_categories', action: 'edit', id: '1' },
      '/bloggity/blog_categories/1/edit'
    )
  end

  # Note: blog_assets routes exist in routes.rb but controller may not be implemented
  # Skipping blog_assets tests for now

  # BLOG COMMENTS ROUTES
  test "blog comments routes should be recognized" do
    assert_recognizes(
      { controller: 'bloggity/blog_comments', action: 'index' },
      '/bloggity/blog_comments'
    )
    
    assert_recognizes(
      { controller: 'bloggity/blog_comments', action: 'show', id: '1' },
      '/bloggity/blog_comments/1'
    )
    
    assert_recognizes(
      { controller: 'bloggity/blog_comments', action: 'approve', id: '1' },
      '/bloggity/blog_comments/1/approve'
    )
  end

  # CUSTOM ROUTES
  test "custom routes should be recognized" do
    assert_recognizes(
      { controller: 'bloggity/blog_comments', action: 'recent_comments' },
      '/bloggity/blog_comments_new'
    )
    
    assert_recognizes(
      { controller: 'bloggity/blog_posts', action: 'blog_search' },
      '/bloggity/blog_search'
    )
  end

  # SEO-FRIENDLY ROUTES
  test "seo friendly routes should be recognized" do
    assert_recognizes(
      { controller: 'bloggity/blog_posts', action: 'index', blog_url_id_or_id: 'test-blog' },
      '/bloggity/test-blog'
    )
    
    assert_recognizes(
      { controller: 'bloggity/blog_posts', action: 'show', blog_url_id_or_id: 'test-blog', id: '1' },
      '/bloggity/test-blog/1'
    )
    
    assert_recognizes(
      { controller: 'bloggity/blog_posts', action: 'index', blog_url_id_or_id: 'blog' },
      '/bloggity/blog'
    )
  end

  # HTTP VERBS TESTS
  test "post routes should be recognized" do
    assert_recognizes(
      { controller: 'bloggity/blogs', action: 'create' },
      { path: '/bloggity/blogs', method: :post }
    )
    
    assert_recognizes(
      { controller: 'bloggity/blog_posts', action: 'create', blog_id: '1' },
      { path: '/bloggity/blogs/1/blog_posts', method: :post }
    )
    
    assert_recognizes(
      { controller: 'bloggity/blog_posts', action: 'create_asset', blog_id: '1' },
      { path: '/bloggity/blogs/1/blog_posts/create_asset', method: :post }
    )
  end

  test "put and patch routes should be recognized" do
    assert_recognizes(
      { controller: 'bloggity/blogs', action: 'update', id: '1' },
      { path: '/bloggity/blogs/1', method: :patch }
    )
    
    assert_recognizes(
      { controller: 'bloggity/blogs', action: 'update', id: '1' },
      { path: '/bloggity/blogs/1', method: :put }
    )
    
    assert_recognizes(
      { controller: 'bloggity/blog_posts', action: 'update', blog_id: '1', id: '2' },
      { path: '/bloggity/blogs/1/blog_posts/2', method: :patch }
    )
  end

  test "delete routes should be recognized" do
    assert_recognizes(
      { controller: 'bloggity/blogs', action: 'destroy', id: '1' },
      { path: '/bloggity/blogs/1', method: :delete }
    )
    
    assert_recognizes(
      { controller: 'bloggity/blog_posts', action: 'destroy', blog_id: '1', id: '2' },
      { path: '/bloggity/blogs/1/blog_posts/2', method: :delete }
    )
  end

  # ROUTE GENERATION TESTS  
  test "engine should provide route helpers" do
    assert_respond_to self, :bloggity
    assert bloggity.respond_to?(:blogs_path)
    assert bloggity.respond_to?(:blog_path)
    assert bloggity.respond_to?(:blog_comments_path)
    assert bloggity.respond_to?(:blog_categories_path)
  end

  test "route helpers should generate correct paths" do
    assert_equal '/bloggity/blogs', bloggity.blogs_path
    assert_equal '/bloggity/blogs/1', bloggity.blog_path(1)
    assert_equal '/bloggity/blog_comments', bloggity.blog_comments_path
    assert_equal '/bloggity/blog_categories', bloggity.blog_categories_path
    assert_equal '/bloggity/blog_comments_new', bloggity.blog_comments_new_path
    assert_equal '/bloggity/blog_search', bloggity.blog_search_path
  end

  test "nested route helpers should work" do
    assert_equal '/bloggity/blogs/1/blog_posts', bloggity.blog_blog_posts_path(1)
    assert_equal '/bloggity/blogs/1/blog_posts/2', bloggity.blog_blog_post_path(1, 2)
    assert_equal '/bloggity/blogs/1/blog_posts/new', bloggity.new_blog_blog_post_path(1)
    assert_equal '/bloggity/blogs/1/blog_posts/2/edit', bloggity.edit_blog_blog_post_path(1, 2)
    assert_equal '/bloggity/blogs/1/feed', bloggity.feed_blog_path(1)
  end

  test "member route helpers should work" do
    assert_equal '/bloggity/blogs/1/blog_posts/pending', bloggity.pending_blog_blog_posts_path(1)
    assert_equal '/bloggity/blogs/1/blog_posts/2/close', bloggity.close_blog_blog_post_path(1, 2)
    assert_equal '/bloggity/blog_comments/1/approve', bloggity.approve_blog_comment_path(1)
  end
end