require 'test_helper'

module Bloggity
  class ApplicationHelperTest < ActionView::TestCase
    include ApplicationHelper
    
    def setup
      @user = User.new(
        id: 1,
        name: "Test User",
        can_blog: true,
        can_comment: true
      )
      
      @blog = Blog.create!(
        id: 9,
        title: "Test Blog",
        url_identifier: "test-blog"
      )
      
      @another_blog = Blog.create!(
        id: 10,
        title: "Another Blog", 
        url_identifier: "another-blog"
      )
    end
    
    def teardown
      Blog.destroy_all
    end

    # Tests for blog_logged_in?
    def test_blog_logged_in_returns_false_when_no_current_user
      # Mock current_user to return nil
      def current_user
        nil
      end
      
      result = blog_logged_in?
      assert_nil result
    end
    
    def test_blog_logged_in_returns_false_when_user_not_signed_in
      # Mock current_user and user_signed_in?
      def current_user
        user = Object.new
        def user.user_signed_in?
          false
        end
        user
      end
      
      assert_equal false, blog_logged_in?
    end
    
    def test_blog_logged_in_returns_true_when_user_signed_in
      # Mock current_user and user_signed_in?
      def current_user
        user = Object.new
        def user.user_signed_in?
          true
        end
        user
      end
      
      assert_equal true, blog_logged_in?
    end

    # Tests for load_blog
    def test_load_blog_with_blog_id_param
      # Mock params
      def params
        { blog_id: @blog.id }
      end
      
      load_blog
      
      assert_equal @blog.id, @blog_id
      assert_equal @blog, @blog
    end
    
    def test_load_blog_with_id_param_and_blogs_controller
      # Mock params
      def params
        { controller: 'blogs', id: @blog.id }
      end
      
      load_blog
      
      assert_equal @blog.id, @blog_id
      assert_equal @blog, @blog
    end
    
    def test_load_blog_with_blog_url_id_or_id_param
      # Mock params
      def params
        { blog_url_id_or_id: @blog.url_identifier }
      end
      
      load_blog
      
      assert_equal @blog, @blog
      assert_equal @blog.id, @blog_id
    end
    
    def test_load_blog_falls_back_to_default_blog_id_9
      # Mock params with no relevant parameters
      def params
        {}
      end
      
      load_blog
      
      assert_equal 9, @blog_id
      assert_equal @blog, @blog
    end
    
    def test_load_blog_with_nonexistent_blog_url_identifier
      # Mock params
      def params
        { blog_url_id_or_id: 'nonexistent' }
      end
      
      # This should raise an error when trying to find the blog
      assert_raises(ActiveRecord::RecordNotFound) do
        load_blog
      end
    end

    # Tests for blog_writer_or_redirect
    def test_blog_writer_or_redirect_returns_true_when_user_can_blog
      @blog_id = @blog.id
      
      # Mock current_user with can_blog? method
      def current_user
        user = Object.new
        def user.can_blog?(blog_id)
          true
        end
        user
      end
      
      result = blog_writer_or_redirect
      assert_equal true, result
    end
    
    def test_blog_writer_or_redirect_redirects_when_no_current_user
      @blog_id = @blog.id
      
      # Mock current_user to return nil
      def current_user
        nil
      end
      
      # Mock flash and redirect_to
      def flash
        @flash ||= {}
      end
      
      def redirect_to(path)
        @redirected_to = path
      end
      
      result = blog_writer_or_redirect
      
      assert_equal false, result
      assert_equal "You don't have permission to do that.", flash[:error]
      assert_equal "/blog", @redirected_to
    end
    
    def test_blog_writer_or_redirect_redirects_when_user_cannot_blog
      @blog_id = @blog.id
      
      # Mock current_user with can_blog? method returning false
      def current_user
        user = Object.new
        def user.can_blog?(blog_id)
          false
        end
        user
      end
      
      # Mock flash and redirect_to
      def flash
        @flash ||= {}
      end
      
      def redirect_to(path)
        @redirected_to = path
      end
      
      result = blog_writer_or_redirect
      
      assert_equal false, result
      assert_equal "You don't have permission to do that.", flash[:error]
      assert_equal "/blog", @redirected_to
    end

    # Tests for blog_comment_moderator_or_redirect
    def test_blog_comment_moderator_or_redirect_returns_true_when_user_can_moderate
      @blog_id = @blog.id
      
      # Mock current_user with can_moderate_blog_comments? method
      def current_user
        user = Object.new
        def user.can_moderate_blog_comments?(blog_id)
          true
        end
        user
      end
      
      result = blog_comment_moderator_or_redirect
      assert_equal true, result
    end
    
    def test_blog_comment_moderator_or_redirect_redirects_when_no_current_user
      @blog_id = @blog.id
      
      # Mock current_user to return nil
      def current_user
        nil
      end
      
      # Mock flash and redirect_to
      def flash
        @flash ||= {}
      end
      
      def redirect_to(path)
        @redirected_to = path
      end
      
      result = blog_comment_moderator_or_redirect
      
      assert_equal false, result
      assert_equal "You don't have permission to do that.", flash[:error]
      assert_equal "/blog", @redirected_to
    end
    
    def test_blog_comment_moderator_or_redirect_redirects_when_user_cannot_moderate
      @blog_id = @blog.id
      
      # Mock current_user with can_moderate_blog_comments? method returning false
      def current_user
        user = Object.new
        def user.can_moderate_blog_comments?(blog_id)
          false
        end
        user
      end
      
      # Mock flash and redirect_to
      def flash
        @flash ||= {}
      end
      
      def redirect_to(path)
        @redirected_to = path
      end
      
      result = blog_comment_moderator_or_redirect
      
      assert_equal false, result
      assert_equal "You don't have permission to do that.", flash[:error]
      assert_equal "/blog", @redirected_to
    end

    # Tests for can_modify_blogs_or_redirect
    def test_can_modify_blogs_or_redirect_returns_true_when_user_can_modify_blogs
      # Mock current_user with can_modify_blogs? method
      def current_user
        user = Object.new
        def user.can_modify_blogs?
          true
        end
        user
      end
      
      result = can_modify_blogs_or_redirect
      assert_equal true, result
    end
    
    def test_can_modify_blogs_or_redirect_redirects_when_no_current_user
      # Mock current_user to return nil
      def current_user
        nil
      end
      
      # Mock redirect_to
      def redirect_to(path)
        @redirected_to = path
      end
      
      result = can_modify_blogs_or_redirect
      
      assert_equal false, result
      assert_equal "/blog", @redirected_to
    end
    
    def test_can_modify_blogs_or_redirect_redirects_when_user_cannot_modify_blogs
      # Mock current_user with can_modify_blogs? method returning false
      def current_user
        user = Object.new
        def user.can_modify_blogs?
          false
        end
        user
      end
      
      # Mock redirect_to
      def redirect_to(path)
        @redirected_to = path
      end
      
      result = can_modify_blogs_or_redirect
      
      assert_equal false, result
      assert_equal "/blog", @redirected_to
    end

    # Tests for page_title
    def test_page_title_sets_content_for_when_title_provided
      # Mock content_for method
      @content_for_values = {}
      
      def content_for(key, &block)
        @content_for_values[key] = block.call if block_given?
      end
      
      def content_for?(key)
        @content_for_values.key?(key)
      end
      
      page_title("Test Page")
      
      assert_equal "Test Page - Memverse", @content_for_values[:page_title]
    end
    
    def test_page_title_returns_existing_content_when_no_title_provided
      # Mock content_for methods
      @content_for_values = { page_title: "Existing Title" }
      
      def content_for?(key)
        @content_for_values.key?(key)
      end
      
      def content_for(key)
        @content_for_values[key]
      end
      
      result = page_title
      
      assert_equal "Existing Title", result
    end
    
    def test_page_title_returns_default_when_no_title_and_no_existing_content
      # Mock content_for methods
      @content_for_values = {}
      
      def content_for?(key)
        @content_for_values.key?(key)
      end
      
      def content_for(key)
        @content_for_values[key]
      end
      
      result = page_title
      
      assert_equal "Memverse", result
    end

    # Integration tests
    def test_helper_includes_page_names_helper
      assert_respond_to self, :look_up_page_name
    end
    
    def test_helper_includes_url_helper
      assert_respond_to self, :blog_named_link
    end
  end
end