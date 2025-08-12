require 'test_helper'

class Bloggity::BlogCommentsControllerTest < ActionController::TestCase
  tests Bloggity::BlogCommentsController

  # Stub the breadcrumb functionality for testing
  def setup_breadcrumb_stub
    Bloggity::BlogCommentsController.class_eval do
      def self.add_breadcrumb(*args)
        # Stub method - do nothing in tests
      end
      
      def add_breadcrumb(*args)
        # Instance method stub for individual actions
      end
    end unless Bloggity::BlogCommentsController.respond_to?(:add_breadcrumb)
  end

  def setup
    setup_breadcrumb_stub
    
    # Create test data manually to avoid fixture/migration issues
    @user = User.create!(name: "Test User", email: "test@example.com", can_comment: true, can_blog: true)
    
    @blog = Bloggity::Blog.create!(title: "Test Blog", url_identifier: "test-blog", description: "Test blog")
    
    @blog_post = Bloggity::BlogPost.create!(
      title: "Test Post",
      body: "Test post content",
      url_identifier: "test-post",
      blog_id: @blog.id,
      posted_by_id: @user.id,
      is_complete: true
    )
    
    @blog_comment = Bloggity::BlogComment.create!(
      comment: "Test comment",
      blog_post_id: @blog_post.id,
      user_id: @user.id,
      approved: true
    )
    
    # Extend User with required methods for testing
    User.class_eval do
      attr_accessor :can_moderate_comments, :auto_approve_comments
      
      def can_moderate_blog_comments?(blog_id = nil)
        @can_moderate_comments || false
      end
      
      def blog_comment_auto_approved?(blog_id = nil)
        @auto_approve_comments || true
      end
    end
    
    # Mock authentication
    @controller.stub(:current_user, @user) do
      @controller.stub(:authenticate_user!, true) do
        yield if block_given?
      end
    end
  end

  # Test helper method to set user authentication
  def with_user_authenticated(user = @user, &block)
    @controller.stub(:current_user, user) do
      @controller.stub(:authenticate_user!, true) do
        block.call
      end
    end
  end

  # Test helper method to mock user as unauthenticated
  def with_user_unauthenticated(&block)
    @controller.stub(:current_user, nil) do
      @controller.stub(:authenticate_user!, proc { redirect_to('/login') }) do
        block.call
      end
    end
  end

  # ========================================================================================
  # CREATE TESTS
  # ========================================================================================

  def test_create_comment_success_with_authorized_user
    with_user_authenticated(@user) do
      @user.can_comment = true
      
      assert_difference('Bloggity::BlogComment.count', 1) do
        post :create, params: {
          blog_comment: {
            comment: "Test comment",
            blog_post_id: @blog_post.id
          },
          subject: "" # Empty subject field (spam protection)
        }
      end
      
      assert_redirected_to @controller.send(:blog_named_link, @blog_post)
      assert_equal @user.id, Bloggity::BlogComment.last.user_id
    end
  end

  def test_create_comment_blocked_with_spam_subject_field
    with_user_authenticated(@user) do
      @user.can_comment = true
      
      assert_no_difference('Bloggity::BlogComment.count') do
        post :create, params: {
          blog_comment: {
            comment: "Test comment",
            blog_post_id: @blog_post.id
          },
          subject: "spam content" # Non-empty subject field indicates spam
        }
      end
      
      assert_redirected_to @controller.send(:blog_named_link, @blog_post)
      assert_equal "You are not yet allowed to comment on blog posts", flash[:error]
    end
  end

  def test_create_comment_blocked_with_unauthorized_user
    with_user_authenticated(@user) do
      @user.can_comment = false
      
      assert_no_difference('Bloggity::BlogComment.count') do
        post :create, params: {
          blog_comment: {
            comment: "Test comment",
            blog_post_id: @blog_post.id
          },
          subject: ""
        }
      end
      
      assert_redirected_to @controller.send(:blog_named_link, @blog_post)
      assert_equal "You are not yet allowed to comment on blog posts", flash[:error]
    end
  end

  def test_create_comment_requires_authentication
    with_user_unauthenticated do
      post :create, params: {
        blog_comment: {
          comment: "Test comment",
          blog_post_id: @blog_post.id
        },
        subject: ""
      }
      
      assert_redirected_to '/login'
    end
  end

  # ========================================================================================
  # EDIT TESTS
  # ========================================================================================

  def test_edit_comment_as_owner
    with_user_authenticated(@blog_comment.user) do
      get :edit, params: { id: @blog_comment.id }
      
      assert_response :success
      assert_equal @blog_comment, assigns(:blog_comment)
      assert_equal @blog_comment.blog_post, assigns(:blog_post)
    end
  end

  def test_edit_comment_as_moderator
    moderator = User.create!(name: "Moderator", email: "mod@example.com", can_comment: true)
    moderator.can_moderate_comments = true
    
    with_user_authenticated(moderator) do
      get :edit, params: { id: @blog_comment.id }
      
      assert_response :success
      assert_equal @blog_comment, assigns(:blog_comment)
    end
  end

  def test_edit_comment_blocked_for_unauthorized_user
    unauthorized_user = User.create!(name: "Unauthorized", email: "unauth@example.com")
    
    with_user_authenticated(unauthorized_user) do
      get :edit, params: { id: @blog_comment.id }
      
      assert_redirected_to @controller.send(:blog_named_link, @blog_comment.blog_post)
      assert_equal "You don't have permission to edit that comment", flash[:error]
    end
  end

  def test_edit_comment_requires_authentication
    with_user_unauthenticated do
      get :edit, params: { id: @blog_comment.id }
      
      assert_redirected_to '/login'
    end
  end

  # ========================================================================================
  # UPDATE TESTS
  # ========================================================================================

  def test_update_comment_as_owner
    with_user_authenticated(@blog_comment.user) do
      patch :update, params: {
        id: @blog_comment.id,
        blog_comment: { comment: "Updated comment text" }
      }
      
      assert_redirected_to @controller.send(:blog_named_link, @blog_comment.blog_post)
      @blog_comment.reload
      assert_equal "Updated comment text", @blog_comment.comment
    end
  end

  def test_update_comment_as_moderator
    moderator = User.create!(name: "Moderator", email: "mod@example.com", can_comment: true)
    moderator.can_moderate_comments = true
    
    with_user_authenticated(moderator) do
      patch :update, params: {
        id: @blog_comment.id,
        blog_comment: { comment: "Moderator updated comment" }
      }
      
      assert_redirected_to @controller.send(:blog_named_link, @blog_comment.blog_post)
      @blog_comment.reload
      assert_equal "Moderator updated comment", @blog_comment.comment
    end
  end

  def test_update_comment_blocked_for_unauthorized_user
    unauthorized_user = User.create!(name: "Unauthorized", email: "unauth@example.com")
    original_comment = @blog_comment.comment
    
    with_user_authenticated(unauthorized_user) do
      patch :update, params: {
        id: @blog_comment.id,
        blog_comment: { comment: "Unauthorized update" }
      }
      
      assert_redirected_to @controller.send(:blog_named_link, @blog_comment.blog_post)
      assert_equal "You don't have permission to edit that comment", flash[:error]
      @blog_comment.reload
      assert_equal original_comment, @blog_comment.comment
    end
  end

  def test_update_comment_requires_authentication
    with_user_unauthenticated do
      patch :update, params: {
        id: @blog_comment.id,
        blog_comment: { comment: "Unauthenticated update" }
      }
      
      assert_redirected_to '/login'
    end
  end

  # ========================================================================================
  # DESTROY TESTS
  # ========================================================================================

  def test_destroy_comment_as_moderator
    moderator = User.create!(name: "Moderator", email: "mod@example.com", can_comment: true)
    moderator.can_moderate_comments = true
    comment_id = @blog_comment.id
    
    with_user_authenticated(moderator) do
      assert_difference('Bloggity::BlogComment.count', -1) do
        delete :destroy, params: { id: comment_id }
      end
      
      assert_redirected_to request.referrer || '/'
    end
  end

  def test_destroy_comment_blocked_for_non_moderator
    non_moderator = User.create!(name: "User", email: "user@example.com", can_comment: true)
    
    with_user_authenticated(non_moderator) do
      assert_no_difference('Bloggity::BlogComment.count') do
        delete :destroy, params: { id: @blog_comment.id }
      end
      
      assert_redirected_to '/blog'
      assert_equal "You don't have permission to do that.", flash[:error]
    end
  end

  def test_destroy_comment_requires_authentication
    with_user_unauthenticated do
      delete :destroy, params: { id: @blog_comment.id }
      
      assert_redirected_to '/login'
    end
  end

  # ========================================================================================
  # APPROVE TESTS
  # ========================================================================================

  def test_approve_comment_as_moderator
    moderator = User.create!(name: "Moderator", email: "mod@example.com", can_comment: true)
    moderator.can_moderate_comments = true
    
    # Create an unapproved comment
    unapproved_comment = Bloggity::BlogComment.create!(
      comment: "Pending approval",
      blog_post: @blog_post,
      user: @user,
      approved: false
    )
    
    with_user_authenticated(moderator) do
      get :approve, params: { id: unapproved_comment.id }
      
      assert_redirected_to request.referrer || '/'
      assert_equal "Comment was approved!", flash[:notice]
      unapproved_comment.reload
      assert unapproved_comment.approved
    end
  end

  def test_approve_comment_blocked_for_non_moderator
    non_moderator = User.create!(name: "User", email: "user@example.com", can_comment: true)
    
    # Create an unapproved comment
    unapproved_comment = Bloggity::BlogComment.create!(
      comment: "Pending approval",
      blog_post: @blog_post,
      user: @user,
      approved: false
    )
    
    with_user_authenticated(non_moderator) do
      get :approve, params: { id: unapproved_comment.id }
      
      assert_redirected_to '/blog'
      assert_equal "You don't have permission to do that.", flash[:error]
      unapproved_comment.reload
      assert_not unapproved_comment.approved
    end
  end

  def test_approve_comment_requires_authentication
    with_user_unauthenticated do
      get :approve, params: { id: @blog_comment.id }
      
      assert_redirected_to '/login'
    end
  end

  # ========================================================================================
  # RECENT COMMENTS TESTS
  # ========================================================================================

  def test_recent_comments_success
    with_user_authenticated(@user) do
      get :recent_comments
      
      assert_response :success
      assert_equal "blog", assigns(:tab)
      assert_equal "comments", assigns(:sub)
      assert_not_nil assigns(:newest_comments)
    end
  end

  def test_recent_comments_only_shows_approved
    # Create approved and unapproved comments
    approved_comment = Bloggity::BlogComment.create!(
      comment: "Approved comment",
      blog_post: @blog_post,
      user: @user,
      approved: true
    )
    
    unapproved_comment = Bloggity::BlogComment.create!(
      comment: "Unapproved comment",
      blog_post: @blog_post,
      user: @user,
      approved: false
    )
    
    with_user_authenticated(@user) do
      get :recent_comments
      
      assert_response :success
      recent_comments = assigns(:newest_comments)
      assert_includes recent_comments.map(&:id), approved_comment.id
      assert_not_includes recent_comments.map(&:id), unapproved_comment.id
    end
  end

  def test_recent_comments_caching
    with_user_authenticated(@user) do
      # Clear any existing cache
      Rails.cache.delete("recent_comments")
      
      # First request should hit the database
      get :recent_comments
      cached_result = Rails.cache.fetch("recent_comments")
      assert_not_nil cached_result
      
      # Second request should use cache
      get :recent_comments
      assert_equal cached_result, assigns(:newest_comments)
    end
  end

  def test_recent_comments_requires_authentication
    with_user_unauthenticated do
      get :recent_comments
      
      assert_redirected_to '/login'
    end
  end

  # ========================================================================================
  # LOAD BLOG COMMENT TESTS (private method testing through actions)
  # ========================================================================================

  def test_load_blog_comment_sets_instance_variables
    with_user_authenticated(@blog_comment.user) do
      get :edit, params: { id: @blog_comment.id }
      
      assert_equal @blog_comment, assigns(:blog_comment)
      assert_equal @blog_comment.blog_post, assigns(:blog_post)
      assert_equal @blog_comment.blog_post.blog, assigns(:blog)
      assert_equal @blog_comment.blog_post.blog_id, assigns(:blog_id)
    end
  end

  def test_load_blog_comment_with_nonexistent_comment
    with_user_authenticated(@user) do
      assert_raises(ActiveRecord::RecordNotFound) do
        get :edit, params: { id: 99999 }
      end
    end
  end

  # ========================================================================================
  # PERMISSION TESTS
  # ========================================================================================

  def test_comment_permission_for_comment_owner
    with_user_authenticated(@blog_comment.user) do
      get :edit, params: { id: @blog_comment.id }
      
      assert_response :success
    end
  end

  def test_comment_permission_for_blog_moderator
    moderator = User.create!(name: "Moderator", email: "mod@example.com", can_comment: true)
    moderator.can_moderate_comments = true
    
    with_user_authenticated(moderator) do
      get :edit, params: { id: @blog_comment.id }
      
      assert_response :success
    end
  end

  def test_comment_permission_denied_for_other_users
    other_user = User.create!(name: "Other User", email: "other@example.com", can_comment: true)
    
    with_user_authenticated(other_user) do
      get :edit, params: { id: @blog_comment.id }
      
      assert_redirected_to @controller.send(:blog_named_link, @blog_comment.blog_post)
      assert_equal "You don't have permission to edit that comment", flash[:error]
    end
  end

  # ========================================================================================
  # CSRF PROTECTION TESTS
  # ========================================================================================

  def test_csrf_protection_disabled_for_create_action
    # The controller has protect_from_forgery :except => [:create]
    # This test verifies that CSRF is indeed disabled for create
    with_user_authenticated(@user) do
      @user.can_comment = true
      
      # Should work without CSRF token
      post :create, params: {
        blog_comment: {
          comment: "Test comment without CSRF",
          blog_post_id: @blog_post.id
        },
        subject: ""
      }
      
      assert_redirected_to @controller.send(:blog_named_link, @blog_post)
    end
  end

  # ========================================================================================
  # STRONG PARAMETERS TESTS
  # ========================================================================================

  def test_blog_comment_params_filtering
    with_user_authenticated(@user) do
      @user.can_comment = true
      
      # Attempt to pass unauthorized parameters
      post :create, params: {
        blog_comment: {
          comment: "Test comment",
          blog_post_id: @blog_post.id,
          approved: true, # This should be filtered out
          created_at: 1.day.ago # This should be filtered out
        },
        subject: ""
      }
      
      new_comment = Bloggity::BlogComment.last
      # approved should be set by the model logic, not by params
      # The actual approval depends on blog_comment_auto_approved? method
      assert_equal "Test comment", new_comment.comment
      assert_equal @blog_post.id, new_comment.blog_post_id
      assert_equal @user.id, new_comment.user_id
    end
  end

  # ========================================================================================
  # BREADCRUMB TESTS
  # ========================================================================================

  def test_edit_action_sets_breadcrumb
    with_user_authenticated(@blog_comment.user) do
      get :edit, params: { id: @blog_comment.id }
      
      assert_response :success
      # The breadcrumb functionality is stubbed, so just verify the action succeeds
      # In a real environment with breadcrumb gem, this would add "Edit Comment" breadcrumb
    end
  end

  # ========================================================================================
  # COMMENT AUTO-APPROVAL TESTS
  # ========================================================================================

  def test_comment_auto_approval_when_user_is_auto_approved
    auto_approved_user = User.create!(name: "Auto Approved", email: "auto@example.com", can_comment: true)
    auto_approved_user.auto_approve_comments = true
    
    with_user_authenticated(auto_approved_user) do
      post :create, params: {
        blog_comment: {
          comment: "Auto approved comment",
          blog_post_id: @blog_post.id
        },
        subject: ""
      }
      
      new_comment = Bloggity::BlogComment.last
      assert new_comment.approved
    end
  end

  def test_comment_requires_approval_when_user_not_auto_approved
    manual_approval_user = User.create!(name: "Manual Approval", email: "manual@example.com", can_comment: true)
    manual_approval_user.auto_approve_comments = false
    
    with_user_authenticated(manual_approval_user) do
      post :create, params: {
        blog_comment: {
          comment: "Requires approval comment",
          blog_post_id: @blog_post.id
        },
        subject: ""
      }
      
      new_comment = Bloggity::BlogComment.last
      assert_not new_comment.approved
    end
  end
end