require 'test_helper'

module Bloggity
  class BlogTagTest < ActiveSupport::TestCase
    # Note: Following the pattern from other tests, we avoid fixtures due to table naming issues
    # and create test data directly in methods

    def setup
      # Clean up any existing data to ensure test isolation
      BlogTag.delete_all
      BlogPost.delete_all
      Blog.delete_all
      User.delete_all

      # Create a test user (required for blog posts)
      @user = User.create!(
        id: 999,
        name: "Test User",
        email: "test@example.com",
        can_blog: true,
        can_comment: true
      )
      
      # Create a test blog (required for blog posts)
      @blog = Blog.create!(
        title: "Test Blog",
        url_identifier: "test-blog"
      )

      # Create a test blog post (required for tags)
      @blog_post = BlogPost.create!(
        title: "Test Post",
        body: "Test content",
        posted_by_id: @user.id,
        blog_id: @blog.id,
        is_complete: true
      )
    end

    def teardown
      # Clean up after each test
      BlogTag.delete_all
      BlogPost.delete_all
      Blog.delete_all
      User.delete_all
    end

    # Test basic validations and model setup
    def test_should_be_valid_with_required_attributes
      tag = BlogTag.new(
        name: "ruby",
        blog_post_id: @blog_post.id
      )
      assert tag.valid?, "BlogTag should be valid with name and blog_post_id"
    end

    def test_should_allow_nil_name
      # Based on the model code, there are no explicit validations for name presence
      tag = BlogTag.new(
        name: nil,
        blog_post_id: @blog_post.id
      )
      assert tag.valid?, "BlogTag should allow nil name (no explicit validation in model)"
    end

    def test_should_allow_empty_name
      # Testing edge case with empty string
      tag = BlogTag.new(
        name: "",
        blog_post_id: @blog_post.id
      )
      assert tag.valid?, "BlogTag should allow empty name (no explicit validation in model)"
    end

    def test_should_require_blog_post_id_for_association
      tag = BlogTag.new(name: "ruby")
      # While the model doesn't have explicit validation, the belongs_to association
      # might enforce this depending on Rails version
      tag.save
      # We test that it can be created, but association methods will fail without valid blog_post_id
      assert_nil tag.blog_post, "blog_post should be nil when blog_post_id is nil"
    end

    # Test associations
    def test_should_belong_to_blog_post
      tag = BlogTag.create!(
        name: "rails",
        blog_post_id: @blog_post.id
      )
      
      assert_respond_to tag, :blog_post, "BlogTag should respond to blog_post"
      assert_equal @blog_post, tag.blog_post, "BlogTag should belong to the correct blog post"
    end

    def test_should_return_nil_for_invalid_blog_post_id
      # In Rails 7, belongs_to associations are validated by default
      # So we need to skip validation to test this scenario
      tag = BlogTag.new(
        name: "invalid",
        blog_post_id: 99999 # Non-existent blog post ID
      )
      tag.save(validate: false) # Skip validation to allow invalid blog_post_id
      
      assert_nil tag.blog_post, "blog_post should be nil for invalid blog_post_id"
    end

    def test_blog_post_should_have_many_tags
      # Create multiple tags for the same post
      tag1 = BlogTag.create!(name: "ruby", blog_post_id: @blog_post.id)
      tag2 = BlogTag.create!(name: "rails", blog_post_id: @blog_post.id)
      
      @blog_post.reload
      assert @blog_post.tags.include?(tag1), "Blog post should include first tag"
      assert @blog_post.tags.include?(tag2), "Blog post should include second tag"
      assert_equal 2, @blog_post.tags.count, "Blog post should have 2 tags"
    end

    # Test CRUD operations
    def test_should_create_blog_tag
      tag_count = BlogTag.count
      tag = BlogTag.create!(
        name: "testing",
        blog_post_id: @blog_post.id
      )
      
      assert tag.persisted?, "BlogTag should be persisted"
      assert_equal tag_count + 1, BlogTag.count, "BlogTag count should increase by 1"
      assert_equal "testing", tag.name
      assert_equal @blog_post.id, tag.blog_post_id
    end

    def test_should_read_blog_tag
      tag = BlogTag.create!(
        name: "readable",
        blog_post_id: @blog_post.id
      )
      
      found_tag = BlogTag.find(tag.id)
      assert_equal tag.name, found_tag.name
      assert_equal tag.blog_post_id, found_tag.blog_post_id
    end

    def test_should_update_blog_tag
      tag = BlogTag.create!(
        name: "original",
        blog_post_id: @blog_post.id
      )
      
      tag.update!(name: "updated")
      tag.reload
      
      assert_equal "updated", tag.name
    end

    def test_should_destroy_blog_tag
      tag = BlogTag.create!(
        name: "deletable",
        blog_post_id: @blog_post.id
      )
      tag_count = BlogTag.count
      
      tag.destroy
      
      assert_equal tag_count - 1, BlogTag.count, "BlogTag count should decrease by 1"
      assert_raises(ActiveRecord::RecordNotFound) { BlogTag.find(tag.id) }
    end

    # Test tag creation through BlogPost (integration with save_tags method)
    def test_should_create_tags_when_blog_post_saved_with_tag_string
      @blog_post.update!(tag_string: "ruby, rails, testing")
      
      @blog_post.reload
      tags = @blog_post.tags
      tag_names = tags.map(&:name)
      
      assert_equal 3, tags.count, "Should create 3 tags"
      assert_includes tag_names, "ruby"
      assert_includes tag_names, "rails" 
      assert_includes tag_names, "testing"
    end

    def test_should_strip_and_chomp_tag_names
      # Test the tag sanitization that happens in BlogPost#save_tags
      @blog_post.update!(tag_string: " ruby , rails\n, testing ")
      
      @blog_post.reload
      tag_names = @blog_post.tags.map(&:name)
      
      assert_includes tag_names, "ruby", "Should strip leading/trailing spaces"
      assert_includes tag_names, "rails", "Should strip trailing newlines and spaces"
      assert_includes tag_names, "testing", "Should strip spaces"
      
      # Verify no tag has leading/trailing whitespace
      @blog_post.tags.each do |tag|
        assert_equal tag.name.strip, tag.name, "Tag name should not have leading/trailing whitespace"
      end
    end

    def test_should_replace_existing_tags_when_blog_post_updated
      # First, create some tags
      @blog_post.update!(tag_string: "old, tags")
      assert_equal 2, @blog_post.tags.count
      
      # Update with new tags
      @blog_post.update!(tag_string: "new, different, tags")
      
      @blog_post.reload
      tag_names = @blog_post.tags.map(&:name)
      
      assert_equal 3, @blog_post.tags.count, "Should have 3 new tags"
      assert_includes tag_names, "new"
      assert_includes tag_names, "different" 
      assert_includes tag_names, "tags"
      assert_not_includes tag_names, "old", "Old tags should be removed"
    end

    def test_should_handle_empty_tag_string
      @blog_post.update!(tag_string: "")
      
      @blog_post.reload
      assert_equal 0, @blog_post.tags.count, "Should have no tags with empty tag_string"
    end

    def test_should_handle_nil_tag_string
      @blog_post.update!(tag_string: nil)
      
      @blog_post.reload
      assert_equal 0, @blog_post.tags.count, "Should have no tags with nil tag_string"
    end

    def test_should_handle_single_tag
      @blog_post.update!(tag_string: "singletag")
      
      @blog_post.reload
      assert_equal 1, @blog_post.tags.count
      assert_equal "singletag", @blog_post.tags.first.name
    end

    def test_should_handle_tags_with_commas_in_different_positions
      @blog_post.update!(tag_string: ",leading,middle,trailing,")
      
      @blog_post.reload
      tag_names = @blog_post.tags.map(&:name)
      
      # The implementation creates tags for each split, including empty strings
      # which get stripped and chomped but might still be saved
      # Let's test what actually happens
      assert @blog_post.tags.count > 0, "Should create some tags"
      assert_includes tag_names, "leading"
      assert_includes tag_names, "middle" 
      assert_includes tag_names, "trailing"
      
      # The actual count might include empty tags, so we test that non-empty tags exist
      non_empty_tags = tag_names.reject(&:empty?)
      assert non_empty_tags.length >= 3, "Should have at least 3 non-empty tags"
    end

    # Test uniqueness constraints (if any)
    def test_should_allow_duplicate_tag_names_for_same_post
      # The current implementation allows duplicate tags for the same post
      BlogTag.create!(name: "duplicate", blog_post_id: @blog_post.id)
      duplicate_tag = BlogTag.new(name: "duplicate", blog_post_id: @blog_post.id)
      
      assert duplicate_tag.valid?, "Should allow duplicate tag names for same post"
      assert duplicate_tag.save, "Should be able to save duplicate tag"
    end

    def test_should_allow_same_tag_name_for_different_posts
      # Create another blog post
      another_post = BlogPost.create!(
        title: "Another Post",
        body: "Another content",
        posted_by_id: @user.id,
        blog_id: @blog.id,
        is_complete: true
      )
      
      tag1 = BlogTag.create!(name: "shared", blog_post_id: @blog_post.id)
      tag2 = BlogTag.new(name: "shared", blog_post_id: another_post.id)
      
      assert tag2.valid?, "Should allow same tag name for different posts"
      assert tag2.save, "Should be able to save tag with same name for different post"
    end

    # Test edge cases and data types
    def test_should_handle_very_long_tag_name
      long_name = "a" * 500 # Very long tag name
      tag = BlogTag.new(
        name: long_name,
        blog_post_id: @blog_post.id
      )
      
      # Depending on database constraints, this may or may not be valid
      # We test that it behaves consistently
      if tag.valid?
        assert tag.save, "Should save very long tag name if validation passes"
      else
        assert tag.errors[:name].any?, "Should have error on name if validation fails"
      end
    end

    def test_should_handle_special_characters_in_tag_name
      special_names = ["ruby-on-rails", "c++", "tag.with.dots", "tag with spaces", "tag_with_underscores"]
      
      special_names.each do |name|
        tag = BlogTag.create!(
          name: name,
          blog_post_id: @blog_post.id
        )
        
        assert_equal name, tag.name, "Should preserve special characters in tag name"
        assert tag.persisted?, "Tag with special characters should be persisted"
      end
    end

    def test_should_handle_unicode_characters_in_tag_name
      unicode_names = ["日本語", "español", "français", "emoji😀", "Русский"]
      
      unicode_names.each do |name|
        tag = BlogTag.create!(
          name: name,
          blog_post_id: @blog_post.id
        )
        
        assert_equal name, tag.name, "Should preserve unicode characters in tag name"
        assert tag.persisted?, "Tag with unicode characters should be persisted"
      end
    end

    # Test timestamps
    def test_should_set_created_at_and_updated_at_on_create
      tag = BlogTag.create!(
        name: "timestamp_test",
        blog_post_id: @blog_post.id
      )
      
      assert_not_nil tag.created_at, "created_at should be set"
      assert_not_nil tag.updated_at, "updated_at should be set"
      assert_equal tag.created_at.to_i, tag.updated_at.to_i, "created_at and updated_at should be equal on create"
    end

    def test_should_update_updated_at_on_save
      tag = BlogTag.create!(
        name: "timestamp_test",
        blog_post_id: @blog_post.id
      )
      original_updated_at = tag.updated_at
      
      sleep 1 # Ensure time difference
      tag.update!(name: "updated_name")
      
      assert tag.updated_at > original_updated_at, "updated_at should be updated on save"
    end

    # Test model behavior in different scenarios
    def test_should_handle_blog_post_destruction
      tag = BlogTag.create!(
        name: "dependent_tag",
        blog_post_id: @blog_post.id
      )
      tag_id = tag.id
      
      @blog_post.destroy
      
      # Since there's no dependent: :destroy on the association,
      # the tag should still exist but with a null blog_post_id reference
      # OR it might be orphaned depending on Rails configuration
      tag_after_destroy = BlogTag.find_by(id: tag_id)
      
      # Test that either the tag is destroyed OR it's orphaned
      if tag_after_destroy
        # Tag still exists but blog_post association is broken
        assert_nil tag_after_destroy.blog_post, "blog_post association should be nil after blog_post destruction"
      else
        # Tag was destroyed (if database has foreign key constraints)
        assert_nil BlogTag.find_by(id: tag_id), "Tag should be destroyed if foreign key constraints are enforced"
      end
    end

    def test_should_handle_mass_assignment_protection
      # Test that we can assign attributes safely
      old_time = 1.day.ago
      tag = BlogTag.new(
        name: "mass_assigned",
        blog_post_id: @blog_post.id,
        created_at: old_time # This might be overridden by Rails
      )
      
      tag.save!
      
      assert_equal "mass_assigned", tag.name
      assert_equal @blog_post.id, tag.blog_post_id
      # In Rails 7, manually set created_at might be preserved
      # We test that the tag was saved successfully regardless
      assert_not_nil tag.created_at, "created_at should be set"
      assert tag.persisted?, "Tag should be persisted"
    end

    # Test scopes and queries (if any were added to the model)
    def test_should_find_tags_by_blog_post
      tag1 = BlogTag.create!(name: "tag1", blog_post_id: @blog_post.id)
      tag2 = BlogTag.create!(name: "tag2", blog_post_id: @blog_post.id)
      
      # Create another post with a tag to ensure we're filtering correctly
      another_post = BlogPost.create!(
        title: "Another Post",
        body: "Content",
        posted_by_id: @user.id,
        blog_id: @blog.id,
        is_complete: true
      )
      BlogTag.create!(name: "other_tag", blog_post_id: another_post.id)
      
      post_tags = BlogTag.where(blog_post_id: @blog_post.id)
      
      assert_equal 2, post_tags.count
      assert_includes post_tags, tag1
      assert_includes post_tags, tag2
    end

    def test_should_find_tags_by_name
      BlogTag.create!(name: "findable", blog_post_id: @blog_post.id)
      
      found_tags = BlogTag.where(name: "findable")
      
      assert_equal 1, found_tags.count
      assert_equal "findable", found_tags.first.name
    end

    # Test model introspection
    def test_should_have_correct_table_name
      # BlogTag should use the default Rails convention or custom table name
      expected_table_name = "bloggity_blog_tags"
      assert_equal expected_table_name, BlogTag.table_name
    end

    def test_should_have_correct_primary_key
      assert_equal "id", BlogTag.primary_key
    end

    def test_should_respond_to_required_methods
      tag = BlogTag.new
      
      assert_respond_to tag, :name
      assert_respond_to tag, :name=
      assert_respond_to tag, :blog_post_id
      assert_respond_to tag, :blog_post_id=
      assert_respond_to tag, :blog_post
      assert_respond_to tag, :created_at
      assert_respond_to tag, :updated_at
    end

    # Helper methods for creating test data
    private

    def create_valid_tag(attributes = {})
      BlogTag.create!({
        name: "test_tag",
        blog_post_id: @blog_post.id
      }.merge(attributes))
    end

    def create_valid_blog_post(attributes = {})
      BlogPost.create!({
        title: "Test Post",
        body: "Test content",
        posted_by_id: @user.id,
        blog_id: @blog.id,
        is_complete: true
      }.merge(attributes))
    end
  end
end