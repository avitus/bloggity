require 'test_helper'

# Mock Rinku for auto-linking
unless defined?(Rinku)
  class Rinku
    def self.auto_link(text)
      text
    end
  end
end

# Mock Quest model for testing
unless defined?(Quest)
  class Quest
    def self.find_by(*args)
      nil
    end
  end
end

# Mock DOMAIN_NAME constant
unless defined?(DOMAIN_NAME)
  DOMAIN_NAME = 'http://localhost:3000'
end

class BloggityWorkflowsTest < ActionDispatch::IntegrationTest
  def setup
    # Create test users with various permissions
    @admin_user = User.create!(
      name: 'Admin User',
      email: 'admin@test.com',
      can_blog: true,
      can_comment: true
    )

    @blogger_user = User.create!(
      name: 'Blogger User',
      email: 'blogger@test.com',
      can_blog: true,
      can_comment: true
    )

    @commenter_user = User.create!(
      name: 'Commenter User',
      email: 'commenter@test.com',
      can_blog: false,
      can_comment: true
    )

    @guest_user = User.create!(
      name: 'Guest User',
      email: 'guest@test.com',
      can_blog: false,
      can_comment: false
    )

    # Extend User model with required methods for testing
    User.class_eval do
      attr_accessor :can_modify_blogs_flag, :can_moderate_comments_flag, :auto_approve_comments_flag

      def can_modify_blogs?
        @can_modify_blogs_flag || false
      end

      def can_moderate_blog_comments?(blog_id = nil)
        @can_moderate_comments_flag || false
      end

      def blog_comment_auto_approved?(blog_id = nil)
        @auto_approve_comments_flag || true
      end

      def user_signed_in?
        true
      end
    end

    # Set admin permissions
    @admin_user.can_modify_blogs_flag = true
    @admin_user.can_moderate_comments_flag = true
    @admin_user.auto_approve_comments_flag = true

    # Create test blogs
    @primary_blog = Bloggity::Blog.create!(
      title: 'Primary Test Blog',
      subtitle: 'Main blog for testing',
      url_identifier: 'primary-test-blog'
    )

    @secondary_blog = Bloggity::Blog.create!(
      title: 'Secondary Test Blog',
      subtitle: 'Secondary blog for multi-blog testing',
      url_identifier: 'secondary-test-blog'
    )

    # Create test categories
    @test_category = Bloggity::BlogCategory.create!(name: 'Test Category')

    # Mock authentication for integration tests
    setup_authentication_mocks
  end

  private

  def setup_authentication_mocks
    # Mock current_user for the application controller
    ApplicationController.class_eval do
      helper_method :current_user, :blog_logged_in?
      
      def current_user
        @test_current_user || User.first
      end

      def require_login
        redirect_to '/login' unless current_user
      end

      def blog_logged_in?
        current_user.present?
      end
      
      def self.add_breadcrumb(*args)
        # Stub method - do nothing in tests
      end
      
      def add_breadcrumb(*args)
        # Stub method - do nothing in tests
      end
    end
  end

  def sign_in_as(user)
    ApplicationController.class_eval do
      define_method(:current_user) { user }
    end
  end

  def sign_out
    ApplicationController.class_eval do
      define_method(:current_user) { nil }
    end
  end

  # ======================================================================
  # TEST 1: Complete Blog Workflow
  # Create blog → Create post → Add comments → Publish
  # ======================================================================

  test "complete blog workflow from creation to published post with comments" do
    sign_in_as(@admin_user)

    # Step 1: Create a new blog
    get '/bloggity/blogs/new'
    assert_response :success

    post '/bloggity/blogs', params: {
      blog: {
        title: 'Workflow Test Blog',
        subtitle: 'Testing complete workflow',
        url_identifier: 'workflow-test-blog'
      }
    }
    
    new_blog = Bloggity::Blog.find_by(url_identifier: 'workflow-test-blog')
    assert_not_nil new_blog
    assert_equal 'Workflow Test Blog', new_blog.title

    # Step 2: Create a new blog post (draft)
    get "/bloggity/blogs/#{new_blog.id}/blog_posts/new"
    assert_response :redirect # Should redirect to edit after creating

    # The new action creates and saves a draft post, then redirects to edit
    draft_post = Bloggity::BlogPost.where(blog_id: new_blog.id).last
    assert_not_nil draft_post
    assert_equal false, draft_post.is_complete
    assert_equal @admin_user.id, draft_post.posted_by_id

    # Step 3: Edit the draft post
    put "/bloggity/blogs/#{new_blog.id}/blog_posts/#{draft_post.id}", params: {
      blog_post: {
        title: 'My First Workflow Post',
        body: 'This is the content of my first workflow post.',
        tag_string: 'workflow, test, integration',
        is_complete: false # Keep as draft first
      }
    }

    draft_post.reload
    assert_equal 'My First Workflow Post', draft_post.title
    assert_equal 'This is the content of my first workflow post.', draft_post.body
    assert_equal 'workflow, test, integration', draft_post.tag_string
    assert_equal false, draft_post.is_complete

    # Step 4: Publish the post
    put "/bloggity/blogs/#{new_blog.id}/blog_posts/#{draft_post.id}", params: {
      blog_post: {
        title: 'My First Workflow Post',
        body: 'This is the content of my first workflow post.',
        tag_string: 'workflow, test, integration',
        is_complete: true # Now publish it
      }
    }

    draft_post.reload
    assert_equal true, draft_post.is_complete

    # Step 5: View the published post
    get "/bloggity/#{new_blog.url_identifier}/#{draft_post.url_identifier}"
    assert_response :success

    # Step 6: Add a comment as a different user
    sign_in_as(@commenter_user)
    @commenter_user.auto_approve_comments_flag = true

    post '/bloggity/blog_comments', params: {
      blog_comment: {
        comment: 'Great post! Thanks for sharing.',
        blog_post_id: draft_post.id
      },
      subject: '' # Anti-spam field should be empty
    }

    comment = Bloggity::BlogComment.find_by(blog_post_id: draft_post.id)
    assert_not_nil comment
    assert_equal 'Great post! Thanks for sharing.', comment.comment
    assert_equal @commenter_user.id, comment.user_id
    assert_equal true, comment.approved

    # Step 7: Verify comment appears on post
    get "/bloggity/#{new_blog.url_identifier}/#{draft_post.url_identifier}"
    assert_response :success
    # The comment should be visible since it's approved
  end

  # ======================================================================
  # TEST 2: RSS Feed Functionality
  # ======================================================================

  test "RSS feed contains published posts but not drafts" do
    sign_in_as(@blogger_user)

    # Create published post
    published_post = Bloggity::BlogPost.create!(
      title: 'Published RSS Post',
      body: 'This should appear in RSS feed',
      blog_id: @primary_blog.id,
      posted_by_id: @blogger_user.id,
      is_complete: true,
      url_identifier: 'published-rss-post'
    )

    # Create draft post
    draft_post = Bloggity::BlogPost.create!(
      title: 'Draft RSS Post',
      body: 'This should NOT appear in RSS feed',
      blog_id: @primary_blog.id,
      posted_by_id: @blogger_user.id,
      is_complete: false,
      url_identifier: 'draft-rss-post'
    )

    # Test RSS feed
    get "/bloggity/blogs/#{@primary_blog.id}/feed"
    assert_response :success
    assert_equal 'application/xml', response.content_type

    # Verify published post is in feed
    assert_match 'Published RSS Post', response.body
    # Verify draft post is NOT in feed
    assert_no_match 'Draft RSS Post', response.body

    # Test RSS feed by URL identifier
    get "/bloggity/blogs/#{@primary_blog.url_identifier}/feed"
    assert_response :success
    assert_match 'Published RSS Post', response.body
  end

  # ======================================================================
  # TEST 3: File Upload and Asset Management
  # ======================================================================

  test "asset management workflow" do
    sign_in_as(@blogger_user)

    # Create a blog post first
    blog_post = Bloggity::BlogPost.create!(
      title: 'Post with Assets',
      body: 'Testing asset uploads',
      blog_id: @primary_blog.id,
      posted_by_id: @blogger_user.id,
      is_complete: false,
      url_identifier: 'post-with-assets'
    )

    # Test asset listing
    get "/bloggity/blog_assets"
    assert_response :success

    # Test new asset form
    get "/bloggity/blog_assets/new"
    assert_response :success
  end

  # ======================================================================
  # TEST 4: User Permission Workflows
  # ======================================================================

  test "user permission workflows for different user types" do
    # Test admin user can access everything
    sign_in_as(@admin_user)
    
    get '/bloggity/blogs'
    assert_response :success
    
    get '/bloggity/blogs/new'
    assert_response :success

    post '/bloggity/blogs', params: {
      blog: { title: 'Admin Blog', url_identifier: 'admin-blog' }
    }
    admin_blog = Bloggity::Blog.find_by(url_identifier: 'admin-blog')
    assert_not_nil admin_blog

    # Test blogger user can create posts but not blogs
    sign_in_as(@blogger_user)
    
    get '/bloggity/blogs'
    assert_response :success
    
    get "/bloggity/blogs/#{@primary_blog.id}/blog_posts/new"
    assert_response :redirect # Should create and redirect to edit

    blogger_post = Bloggity::BlogPost.where(blog_id: @primary_blog.id, posted_by_id: @blogger_user.id).last
    assert_not_nil blogger_post

    # Test commenter user can comment but not blog
    sign_in_as(@commenter_user)

    post '/bloggity/blog_comments', params: {
      blog_comment: {
        comment: 'Commenter test comment',
        blog_post_id: blogger_post.id
      },
      subject: ''
    }

    commenter_comment = Bloggity::BlogComment.find_by(user_id: @commenter_user.id)
    assert_not_nil commenter_comment

    # Test guest user has limited access
    sign_in_as(@guest_user)
    
    get '/bloggity/blogs'
    assert_response :success
    
    get "/bloggity/#{@primary_blog.url_identifier}"
    assert_response :success

    # Guest should not be able to comment
    post '/bloggity/blog_comments', params: {
      blog_comment: {
        comment: 'Guest attempted comment',
        blog_post_id: blogger_post.id
      },
      subject: ''
    }
    
    guest_comment = Bloggity::BlogComment.find_by(comment: 'Guest attempted comment')
    assert_nil guest_comment # Should not be created
  end

  # ======================================================================
  # TEST 5: Search Functionality
  # ======================================================================

  test "blog search functionality workflow" do
    sign_in_as(@blogger_user)

    # Create searchable content
    searchable_post = Bloggity::BlogPost.create!(
      title: 'Searchable Integration Test Post',
      body: 'This post contains unique searchable content for integration testing',
      blog_id: @primary_blog.id,
      posted_by_id: @blogger_user.id,
      is_complete: true,
      url_identifier: 'searchable-integration-test-post'
    )

    # Test search page
    get '/bloggity/blog_search'
    assert_response :success

    # Test search functionality (note: actual search may depend on search engine setup)
    get '/bloggity/blog_search', params: { search_param: 'integration' }
    assert_response :success
  end

  # ======================================================================
  # TEST 6: Multi-Blog Support
  # ======================================================================

  test "multi-blog support and management" do
    sign_in_as(@admin_user)

    # Verify multiple blogs exist
    get '/bloggity/blogs'
    assert_response :success

    # Create posts in different blogs
    primary_post = Bloggity::BlogPost.create!(
      title: 'Primary Blog Post',
      body: 'Content for primary blog',
      blog_id: @primary_blog.id,
      posted_by_id: @admin_user.id,
      is_complete: true,
      url_identifier: 'primary-blog-post'
    )

    secondary_post = Bloggity::BlogPost.create!(
      title: 'Secondary Blog Post',
      body: 'Content for secondary blog',
      blog_id: @secondary_blog.id,
      posted_by_id: @admin_user.id,
      is_complete: true,
      url_identifier: 'secondary-blog-post'
    )

    # Test accessing different blogs
    get "/bloggity/#{@primary_blog.url_identifier}"
    assert_response :success

    get "/bloggity/#{@secondary_blog.url_identifier}"
    assert_response :success

    # Test cross-blog post isolation
    get "/bloggity/#{@primary_blog.url_identifier}/#{primary_post.url_identifier}"
    assert_response :success

    get "/bloggity/#{@secondary_blog.url_identifier}/#{secondary_post.url_identifier}"
    assert_response :success

    # Test separate RSS feeds
    get "/bloggity/blogs/#{@primary_blog.id}/feed"
    assert_response :success
    primary_feed = response.body

    get "/bloggity/blogs/#{@secondary_blog.id}/feed"
    assert_response :success
    secondary_feed = response.body

    assert_match 'Primary Blog Post', primary_feed
    assert_no_match 'Secondary Blog Post', primary_feed

    assert_match 'Secondary Blog Post', secondary_feed
    assert_no_match 'Primary Blog Post', secondary_feed
  end

  # ======================================================================
  # TEST 7: SEO URL Routing
  # ======================================================================

  test "SEO-friendly URL routing and access" do
    sign_in_as(@blogger_user)

    # Create post with special characters in title
    seo_post = Bloggity::BlogPost.create!(
      title: 'SEO Test: Special Characters & Symbols!',
      body: 'Testing SEO URL generation',
      blog_id: @primary_blog.id,
      posted_by_id: @blogger_user.id,
      is_complete: true
    )

    # Verify URL identifier is properly parameterized
    assert_equal 'seo-test-special-characters-symbols', seo_post.url_identifier

    # Test accessing via SEO URL
    get "/bloggity/#{@primary_blog.url_identifier}/#{seo_post.url_identifier}"
    assert_response :success

    # Test accessing via ID still works
    get "/bloggity/#{@primary_blog.url_identifier}/#{seo_post.id}"
    assert_response :success

    # Test blog URL identifier routing
    get "/bloggity/#{@primary_blog.url_identifier}"
    assert_response :success
  end

  # ======================================================================
  # TEST 8: Comment Moderation Workflow
  # ======================================================================

  test "comment moderation workflow from submission to approval" do
    sign_in_as(@blogger_user)

    # Create a blog post
    moderation_post = Bloggity::BlogPost.create!(
      title: 'Moderation Test Post',
      body: 'Testing comment moderation',
      blog_id: @primary_blog.id,
      posted_by_id: @blogger_user.id,
      is_complete: true,
      url_identifier: 'moderation-test-post'
    )

    # Create user who needs comment approval
    moderated_user = User.create!(
      name: 'Moderated User',
      email: 'moderated@test.com',
      can_blog: false,
      can_comment: true
    )
    moderated_user.auto_approve_comments_flag = false

    # Submit comment that needs approval
    sign_in_as(moderated_user)
    
    post '/bloggity/blog_comments', params: {
      blog_comment: {
        comment: 'This comment needs approval',
        blog_post_id: moderation_post.id
      },
      subject: ''
    }

    pending_comment = Bloggity::BlogComment.find_by(comment: 'This comment needs approval')
    assert_not_nil pending_comment
    assert_equal false, pending_comment.approved

    # Test moderator can see and approve comment
    sign_in_as(@admin_user)
    @admin_user.can_moderate_comments_flag = true

    get "/bloggity/blog_comments/#{pending_comment.id}/approve"
    assert_response :redirect

    pending_comment.reload
    assert_equal true, pending_comment.approved

    # Test viewing recent comments
    get '/bloggity/blog_comments_new'
    assert_response :success

    # Test moderator can edit comments
    get "/bloggity/blog_comments/#{pending_comment.id}/edit"
    assert_response :success

    put "/bloggity/blog_comments/#{pending_comment.id}", params: {
      blog_comment: { comment: 'Moderator edited this comment' }
    }

    pending_comment.reload
    assert_equal 'Moderator edited this comment', pending_comment.comment

    # Test moderator can delete comments
    assert_difference('Bloggity::BlogComment.count', -1) do
      delete "/bloggity/blog_comments/#{pending_comment.id}"
    end
  end

  # ======================================================================
  # TEST 9: Draft to Publish Workflow
  # ======================================================================

  test "draft to publish workflow with validation" do
    sign_in_as(@blogger_user)

    # Create initial draft
    draft = Bloggity::BlogPost.create!(
      title: 'Draft Article',
      body: 'This is draft content',
      blog_id: @primary_blog.id,
      posted_by_id: @blogger_user.id,
      is_complete: false,
      url_identifier: 'draft-article'
    )

    # Verify draft is not visible publicly
    sign_out
    get "/bloggity/#{@primary_blog.url_identifier}/#{draft.url_identifier}"
    assert_response :redirect
    assert_match 'permission', flash[:error]

    # Sign back in and access draft
    sign_in_as(@blogger_user)
    get "/bloggity/#{@primary_blog.url_identifier}/#{draft.url_identifier}"
    assert_response :success

    # Edit draft
    get "/bloggity/blogs/#{@primary_blog.id}/blog_posts/#{draft.id}/edit"
    assert_response :success

    put "/bloggity/blogs/#{@primary_blog.id}/blog_posts/#{draft.id}", params: {
      blog_post: {
        title: 'Updated Draft Article',
        body: 'Updated draft content with more details',
        tag_string: 'draft, publish, workflow',
        is_complete: false
      }
    }

    draft.reload
    assert_equal 'Updated Draft Article', draft.title
    assert_equal false, draft.is_complete

    # Check pending posts view
    get "/bloggity/blogs/#{@primary_blog.id}/blog_posts/pending"
    assert_response :success

    # Publish the draft
    put "/bloggity/blogs/#{@primary_blog.id}/blog_posts/#{draft.id}", params: {
      blog_post: {
        title: 'Published Article',
        body: 'Now published content',
        tag_string: 'published, workflow',
        is_complete: true
      }
    }

    draft.reload
    assert_equal 'Published Article', draft.title
    assert_equal true, draft.is_complete

    # Verify published post is now publicly accessible
    sign_out
    get "/bloggity/#{@primary_blog.url_identifier}/#{draft.url_identifier}"
    assert_response :success

    # Verify tags were saved
    assert_equal 2, draft.tags.count
    tag_names = draft.tags.pluck(:name)
    assert_includes tag_names, 'published'
    assert_includes tag_names, 'workflow'
  end

  # ======================================================================
  # TEST 10: Tag and Category Management
  # ======================================================================

  test "tag and category management workflow" do
    sign_in_as(@blogger_user)

    # Create post with tags and category
    tagged_post = Bloggity::BlogPost.create!(
      title: 'Tagged and Categorized Post',
      body: 'Testing tags and categories',
      blog_id: @primary_blog.id,
      posted_by_id: @blogger_user.id,
      is_complete: true,
      tag_string: 'ruby, rails, testing, integration',
      category_id: @test_category.id,
      url_identifier: 'tagged-categorized-post'
    )

    # Verify tags were created
    assert_equal 4, tagged_post.tags.count
    tag_names = tagged_post.tags.pluck(:name)
    assert_includes tag_names, 'ruby'
    assert_includes tag_names, 'rails'
    assert_includes tag_names, 'testing'
    assert_includes tag_names, 'integration'

    # Verify category association
    assert_equal @test_category.id, tagged_post.category_id

    # Test filtering by tag
    get "/bloggity/#{@primary_blog.url_identifier}", params: { tag_name: 'ruby' }
    assert_response :success

    # Test filtering by category
    get "/bloggity/#{@primary_blog.url_identifier}", params: { category_id: @test_category.id }
    assert_response :success

    # Test category management
    get '/bloggity/blog_categories'
    assert_response :success

    get '/bloggity/blog_categories/new'
    assert_response :success

    post '/bloggity/blog_categories', params: {
      blog_category: { name: 'New Test Category' }
    }

    new_category = Bloggity::BlogCategory.find_by(name: 'New Test Category')
    assert_not_nil new_category

    # Update post tags
    put "/bloggity/blogs/#{@primary_blog.id}/blog_posts/#{tagged_post.id}", params: {
      blog_post: {
        title: 'Updated Tagged Post',
        body: 'Updated content',
        tag_string: 'updated, modified, changed',
        category_id: new_category.id,
        is_complete: true
      }
    }

    tagged_post.reload
    assert_equal 3, tagged_post.tags.count
    updated_tag_names = tagged_post.tags.pluck(:name)
    assert_includes updated_tag_names, 'updated'
    assert_includes updated_tag_names, 'modified'
    assert_includes updated_tag_names, 'changed'
    assert_equal new_category.id, tagged_post.category_id
  end

  # ======================================================================
  # TEST 11: Error Handling and Edge Cases
  # ======================================================================

  test "error handling and edge cases" do
    sign_in_as(@blogger_user)

    # Test accessing non-existent blog
    get "/bloggity/non-existent-blog"
    assert_response :success # Should fall back to default behavior

    # Test accessing non-existent post
    get "/bloggity/#{@primary_blog.url_identifier}/non-existent-post"
    assert_response :redirect
    assert_match 'permission', flash[:error]

    # Test creating post without required fields
    post "/bloggity/blogs/#{@primary_blog.id}/blog_posts", params: {
      blog_post: {
        title: '', # Empty title
        body: 'Body without title'
      }
    }
    # Should handle validation errors gracefully

    # Test spam protection
    post '/bloggity/blog_comments', params: {
      blog_comment: {
        comment: 'Spam comment',
        blog_post_id: @primary_blog.blog_posts.first.try(:id) || 1
      },
      subject: 'spam content' # Non-empty subject indicates spam
    }

    spam_comment = Bloggity::BlogComment.find_by(comment: 'Spam comment')
    assert_nil spam_comment # Should not be created due to spam protection
  end

  # ======================================================================
  # TEST 12: Performance and Caching
  # ======================================================================

  test "caching and performance optimizations" do
    sign_in_as(@blogger_user)

    # Test recent comments caching
    get '/bloggity/blog_comments_new'
    assert_response :success

    # Clear cache and test again
    Rails.cache.clear
    get '/bloggity/blog_comments_new'
    assert_response :success

    # Test blog post eager loading
    get "/bloggity/#{@primary_blog.url_identifier}"
    assert_response :success
  end
end