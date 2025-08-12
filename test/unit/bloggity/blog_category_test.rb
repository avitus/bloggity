require 'test_helper'

module Bloggity
  class BlogCategoryTest < ActiveSupport::TestCase
    def setup
      @programming = BlogCategory.create!(
        name: "Programming",
        blog_id: 1,
        group_id: 0
      )
      
      @ruby = BlogCategory.create!(
        name: "Ruby",
        parent_id: @programming.id,
        blog_id: 1,
        group_id: 0
      )
      
      @rails = BlogCategory.create!(
        name: "Rails",
        parent_id: @ruby.id,
        blog_id: 1,
        group_id: 0
      )
      
      @web_design = BlogCategory.create!(
        name: "Web Design",
        blog_id: 1,
        group_id: 0
      )
      
      @css = BlogCategory.create!(
        name: "CSS",
        parent_id: @web_design.id,
        blog_id: 1,
        group_id: 0
      )
      
      @blog_two_category = BlogCategory.create!(
        name: "Technology",
        blog_id: 2,
        group_id: 0
      )
    end

    # Test basic CRUD operations
    def test_should_create_blog_category
      category = BlogCategory.new(
        name: "New Category", 
        blog_id: 1,
        group_id: 0
      )
      assert category.save
      assert_not_nil category.id
      assert_equal "New Category", category.name
      assert_equal 1, category.blog_id
      assert_equal 0, category.group_id
    end

    def test_should_read_blog_category
      category = @programming
      assert_equal "Programming", category.name
      assert_equal 1, category.blog_id
      assert_nil category.parent_id
      assert_equal 0, category.group_id
    end

    def test_should_update_blog_category
      category = @programming
      original_name = category.name
      category.name = "Updated Programming"
      assert category.save
      category.reload
      assert_equal "Updated Programming", category.name
      assert_not_equal original_name, category.name
    end

    def test_should_destroy_blog_category
      category = @css
      category_id = category.id
      assert category.destroy
      assert_raise(ActiveRecord::RecordNotFound) do
        BlogCategory.find(category_id)
      end
    end

    # Test parent-child relationships
    def test_should_have_parent_child_relationship
      parent = @programming
      child = @ruby
      
      assert_nil parent.parent_id
      assert_equal parent.id, child.parent_id
    end

    def test_should_create_child_category
      parent = @programming
      child = BlogCategory.new(
        name: "JavaScript",
        parent_id: parent.id,
        blog_id: 1,
        group_id: 0
      )
      assert child.save
      assert_equal parent.id, child.parent_id
    end

    def test_should_handle_nested_categories
      grandparent = @programming
      parent = @ruby
      child = @rails
      
      assert_nil grandparent.parent_id
      assert_equal grandparent.id, parent.parent_id
      assert_equal parent.id, child.parent_id
    end

    def test_should_allow_nil_parent_id
      category = BlogCategory.new(
        name: "Root Category",
        parent_id: nil,
        blog_id: 1,
        group_id: 0
      )
      assert category.save
      assert_nil category.parent_id
    end

    # Test blog association
    def test_should_belong_to_blog
      category = @programming
      assert_equal 1, category.blog_id
      
      # Test with different blog
      category_blog_two = @blog_two_category
      assert_equal 2, category_blog_two.blog_id
    end

    def test_should_create_category_for_specific_blog
      category = BlogCategory.new(
        name: "Blog Two Category",
        blog_id: 2,
        group_id: 0
      )
      assert category.save
      assert_equal 2, category.blog_id
    end

    # Test group_id functionality
    def test_should_have_default_group_id
      category = BlogCategory.new(
        name: "Test Category",
        blog_id: 1
      )
      assert category.save
      assert_equal 0, category.group_id
    end

    def test_should_allow_custom_group_id
      category = BlogCategory.new(
        name: "Grouped Category",
        blog_id: 1,
        group_id: 5
      )
      assert category.save
      assert_equal 5, category.group_id
    end

    # Test validations and edge cases
    def test_should_handle_empty_name
      category = BlogCategory.new(
        name: "",
        blog_id: 1,
        group_id: 0
      )
      # Model has presence validation for name
      assert_not category.save
      assert category.errors[:name].any?
    end

    def test_should_handle_nil_name
      category = BlogCategory.new(
        name: nil,
        blog_id: 1,
        group_id: 0
      )
      # Model has presence validation for name
      assert_not category.save
      assert category.errors[:name].any?
    end

    def test_should_handle_long_name
      long_name = "A" * 1000
      category = BlogCategory.new(
        name: long_name,
        blog_id: 1,
        group_id: 0
      )
      assert category.save
      assert_equal long_name, category.name
    end

    def test_should_handle_special_characters_in_name
      category = BlogCategory.new(
        name: "Category with special chars: !@#$%^&*()",
        blog_id: 1,
        group_id: 0
      )
      assert category.save
      assert_equal "Category with special chars: !@#$%^&*()", category.name
    end

    def test_should_handle_unicode_in_name
      category = BlogCategory.new(
        name: "Catégorie avec des caractères spéciaux",
        blog_id: 1,
        group_id: 0
      )
      assert category.save
      assert_equal "Catégorie avec des caractères spéciaux", category.name
    end

    # Test circular parent references (edge case)
    def test_should_handle_self_as_parent
      category = @programming
      category.parent_id = category.id
      # Note: The model doesn't prevent this, testing current behavior
      assert category.save
      assert_equal category.id, category.parent_id
    end

    # Test finding categories
    def test_should_find_all_categories
      categories = BlogCategory.all
      assert categories.count >= 6 # We have 6 in fixtures
      assert categories.include?(@programming)
      assert categories.include?(@ruby)
    end

    def test_should_find_categories_by_blog
      blog_one_categories = BlogCategory.where(blog_id: 1)
      blog_two_categories = BlogCategory.where(blog_id: 2)
      
      assert blog_one_categories.count >= 5
      assert blog_two_categories.count >= 1
      
      assert blog_one_categories.include?(@programming)
      assert blog_two_categories.include?(@blog_two_category)
    end

    def test_should_find_root_categories
      root_categories = BlogCategory.where(parent_id: nil)
      assert root_categories.include?(@programming)
      assert root_categories.include?(@web_design)
      assert_not root_categories.include?(@ruby)
    end

    def test_should_find_child_categories
      programming_id = @programming.id
      child_categories = BlogCategory.where(parent_id: programming_id)
      assert child_categories.include?(@ruby)
      assert_not child_categories.include?(@programming)
    end

    # Test timestamps
    def test_should_have_timestamps
      category = BlogCategory.new(
        name: "Timestamped Category",
        blog_id: 1,
        group_id: 0
      )
      assert_nil category.created_at
      assert_nil category.updated_at
      
      assert category.save
      
      assert_not_nil category.created_at
      assert_not_nil category.updated_at
      assert category.created_at.is_a?(Time)
      assert category.updated_at.is_a?(Time)
    end

    def test_should_update_timestamps_on_save
      category = @programming
      original_updated_at = category.updated_at
      
      sleep(1) # Ensure time difference
      category.name = "Updated Programming Name"
      category.save
      
      assert category.updated_at > original_updated_at
    end

    # Test mass assignment security (Rails style)
    def test_should_handle_mass_assignment
      attributes = {
        name: "Mass Assigned Category",
        blog_id: 1,
        group_id: 2,
        parent_id: @programming.id
      }
      
      category = BlogCategory.new(attributes)
      assert category.save
      
      assert_equal "Mass Assigned Category", category.name
      assert_equal 1, category.blog_id
      assert_equal 2, category.group_id
      assert_equal @programming.id, category.parent_id
    end

    # Test scopes and queries
    def test_should_order_by_name
      categories = BlogCategory.order(:name)
      names = categories.pluck(:name).compact
      assert_equal names.sort, names
    end

    def test_should_count_categories_by_blog
      blog_1_count = BlogCategory.where(blog_id: 1).count
      blog_2_count = BlogCategory.where(blog_id: 2).count
      
      assert blog_1_count >= 5
      assert blog_2_count >= 1
    end

    # Test associations
    def test_should_have_parent_association
      child = @ruby
      parent = @programming
      
      assert_equal parent, child.parent
      assert_equal parent.id, child.parent_id
    end
    
    def test_should_have_children_association
      parent = @programming
      child = @ruby
      
      assert_includes parent.children, child
      assert_equal 1, parent.children.count
    end
    
    def test_should_have_blog_association
      category = @programming
      # Since the Blog model is minimal, we can't test the actual association
      # but we can test the foreign key
      assert_equal 1, category.blog_id
    end
    
    def test_should_handle_orphaned_category
      orphan = BlogCategory.new(
        name: "Orphan Category",
        parent_id: nil,
        blog_id: 1,
        group_id: 0
      )
      assert orphan.save
      assert_nil orphan.parent
      assert_equal 0, orphan.children.count
    end
    
    def test_should_validate_name_presence
      category = BlogCategory.new(
        blog_id: 1,
        group_id: 0
      )
      assert_not category.valid?
      assert category.errors[:name].include?("can't be blank")
    end

    # Test data integrity
    def test_fixture_data_integrity
      # Verify our test data is loaded correctly
      programming = @programming
      ruby = @ruby
      rails = @rails
      
      assert_equal "Programming", programming.name
      assert_equal "Ruby", ruby.name
      assert_equal "Rails", rails.name
      
      assert_nil programming.parent_id
      assert_equal programming.id, ruby.parent_id
      assert_equal ruby.id, rails.parent_id
      
      assert_equal 1, programming.blog_id
      assert_equal 1, ruby.blog_id
      assert_equal 1, rails.blog_id
    end
  end
end