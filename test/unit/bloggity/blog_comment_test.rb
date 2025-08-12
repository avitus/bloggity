require 'test_helper'

module Bloggity
  class BlogCommentTest < ActiveSupport::TestCase
    
    def setup
      # Create a simple user object that responds to the required methods
      @user = Object.new
      def @user.id; 1; end
      def @user.blog_comment_auto_approved?(blog_id); true; end
      
      # Create a simple blog_post object
      @blog_post = Object.new  
      def @blog_post.id; 1; end
      def @blog_post.blog_id; 1; end
      def @blog_post.updated_at; Time.current; end
      def @blog_post.updated_at=(time); @updated_at = time; end
      def @blog_post.touch; self.updated_at = Time.current; end
      
      @valid_comment = Bloggity::BlogComment.new(
        user_id: 1,
        blog_post_id: 1,
        comment: "This is a test comment"
      )
    end

    # --------------------------------------------------------------------------------------
    # Validation Tests
    # --------------------------------------------------------------------------------------

    test "should be valid with valid attributes" do
      assert @valid_comment.valid?
    end

    test "should require blog_post_id" do
      @valid_comment.blog_post_id = nil
      assert_not @valid_comment.valid?
      assert @valid_comment.errors[:blog_post_id].present?
    end

    test "should require user_id" do
      @valid_comment.user_id = nil
      assert_not @valid_comment.valid?
      assert @valid_comment.errors[:user_id].present?
    end

    test "should require comment" do
      @valid_comment.comment = nil
      assert_not @valid_comment.valid?
      assert @valid_comment.errors[:comment].present?
    end

    test "should not be valid with empty comment" do
      @valid_comment.comment = ""
      assert_not @valid_comment.valid?
      assert @valid_comment.errors[:comment].present?
    end

    test "should not be valid with whitespace-only comment" do
      @valid_comment.comment = "   "
      assert_not @valid_comment.valid?
      assert @valid_comment.errors[:comment].present?
    end

    # --------------------------------------------------------------------------------------
    # Association Tests
    # --------------------------------------------------------------------------------------

    test "should belong to user" do
      comment = Bloggity::BlogComment.new
      assert_respond_to comment, :user
      assert_respond_to comment, :user=
    end

    test "should belong to blog_post" do
      comment = Bloggity::BlogComment.new
      assert_respond_to comment, :blog_post
      assert_respond_to comment, :blog_post=
    end

    test "should have user association" do
      comment = Bloggity::BlogComment.new
      comment.user_id = 1
      assert_equal 1, comment.user_id
    end

    test "should have blog_post association" do
      comment = Bloggity::BlogComment.new
      comment.blog_post_id = 1
      assert_equal 1, comment.blog_post_id
    end

    # --------------------------------------------------------------------------------------
    # Touch Functionality Tests
    # --------------------------------------------------------------------------------------

    test "should have touch relationship with blog_post" do
      # Test that the association has the touch option
      association = Bloggity::BlogComment.reflect_on_association(:blog_post)
      assert association.present?
      assert association.options[:touch]
    end

    # --------------------------------------------------------------------------------------
    # Determine Approval Method Tests
    # --------------------------------------------------------------------------------------

    test "should have determine_approval as before_create callback" do
      callbacks = Bloggity::BlogComment._create_callbacks
      callback_names = callbacks.map(&:filter)
      assert_includes callback_names, :determine_approval
    end

    test "determine_approval method sets approved based on user permissions" do
      comment = Bloggity::BlogComment.new(
        user_id: 1,
        blog_post_id: 1,
        comment: "Test comment"
      )
      
      # Create a mock user
      user = Object.new
      def user.blog_comment_auto_approved?(blog_id)
        true
      end
      
      # Create a mock blog_post
      blog_post = Object.new
      def blog_post.blog_id
        1
      end
      
      # Stub the associations
      comment.define_singleton_method(:user) { user }
      comment.define_singleton_method(:blog_post) { blog_post }
      
      # Call determine_approval directly
      comment.send(:determine_approval)
      
      assert comment.approved
    end
    
    test "determine_approval method sets approved to false when user not auto approved" do
      comment = Bloggity::BlogComment.new(
        user_id: 1,
        blog_post_id: 1,
        comment: "Test comment"
      )
      
      # Create a mock user that returns false
      user = Object.new
      def user.blog_comment_auto_approved?(blog_id)
        false
      end
      
      # Create a mock blog_post
      blog_post = Object.new
      def blog_post.blog_id
        1
      end
      
      # Stub the associations
      comment.define_singleton_method(:user) { user }
      comment.define_singleton_method(:blog_post) { blog_post }
      
      # Call determine_approval directly
      comment.send(:determine_approval)
      
      assert_not comment.approved
    end

    # --------------------------------------------------------------------------------------
    # Auto-approval Logic Integration Tests
    # --------------------------------------------------------------------------------------

    test "determine_approval method returns true to continue callback chain" do
      comment = Bloggity::BlogComment.new(
        user_id: 1,
        blog_post_id: 1,
        comment: "Test comment"
      )
      
      # Create mock associations
      user = Object.new
      def user.blog_comment_auto_approved?(blog_id); true; end
      
      blog_post = Object.new
      def blog_post.blog_id; 1; end
      
      comment.define_singleton_method(:user) { user }
      comment.define_singleton_method(:blog_post) { blog_post }
      
      # The determine_approval method should return true
      result = comment.send(:determine_approval)
      assert_equal true, result
    end

    # --------------------------------------------------------------------------------------
    # Additional Method Tests
    # --------------------------------------------------------------------------------------

    test "should have approved attribute" do
      comment = Bloggity::BlogComment.new
      assert_respond_to comment, :approved
      assert_respond_to comment, :approved=
    end
    
    test "should respond to determine_approval method" do
      comment = Bloggity::BlogComment.new
      assert_respond_to comment, :determine_approval, "BlogComment should have determine_approval method"
    end
  end
end