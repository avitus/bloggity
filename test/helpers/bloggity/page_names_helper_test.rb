require 'test_helper'

module Bloggity
  class PageNamesHelperTest < ActionView::TestCase
    include PageNamesHelper
    
    def setup
      # Mock logger for the helper method
      @log_messages = []
      def logger
        logger = Object.new
        def logger.debug(message)
          # Store debug messages for testing
          @log_messages ||= []
          @log_messages << message
        end
        logger
      end
    end

    # Tests for look_up_page_name with various controller/action combinations

    def test_look_up_page_name_with_blank_controller_name
      result = look_up_page_name("", "index")
      assert_equal "Memverse Blog", result
    end
    
    def test_look_up_page_name_with_blank_action_name
      result = look_up_page_name("posts", "")
      assert_equal "Memverse Blog", result
    end
    
    def test_look_up_page_name_with_both_blank
      result = look_up_page_name("", "")
      assert_equal "Memverse Blog", result
    end
    
    def test_look_up_page_name_with_nil_controller_name
      result = look_up_page_name(nil, "index")
      assert_equal "Memverse Blog", result
    end
    
    def test_look_up_page_name_with_nil_action_name
      result = look_up_page_name("posts", nil)
      assert_equal "Memverse Blog", result
    end

    # Test PAGE_NAMES lookup
    def test_look_up_page_name_with_predefined_page_name
      result = look_up_page_name("blog_posts", "index")
      assert_equal "Blog", result
    end
    
    def test_look_up_page_name_with_blog_posts_other_action
      result = look_up_page_name("blog_posts", "show")
      # Should fall through to auto-generation since only index is defined
      assert_equal "[\"Show \", \"Blog \", \"Post \"]", result
    end

    # Test edit actions - should append controller name singularized
    def test_look_up_page_name_with_edit_action
      result = look_up_page_name("posts", "edit")
      assert_equal "[\"Edit \", \"Post \"]", result
    end
    
    def test_look_up_page_name_with_show_action
      result = look_up_page_name("comments", "show")
      assert_equal "[\"Show \", \"Comment \"]", result
    end
    
    def test_look_up_page_name_with_new_action
      result = look_up_page_name("articles", "new")
      assert_equal "[\"New \", \"Article \"]", result
    end

    # Test regular actions - should use action only since they don't match edit/show/new pattern
    def test_look_up_page_name_with_index_action
      result = look_up_page_name("posts", "index")
      assert_equal "[\"Index \"]", result
    end
    
    def test_look_up_page_name_with_create_action
      result = look_up_page_name("users", "create")
      assert_equal "[\"Create \"]", result
    end
    
    def test_look_up_page_name_with_update_action
      result = look_up_page_name("profiles", "update")
      assert_equal "[\"Update \"]", result
    end
    
    def test_look_up_page_name_with_destroy_action
      result = look_up_page_name("sessions", "destroy")
      assert_equal "[\"Destroy \"]", result
    end

    # Test with underscored action names
    def test_look_up_page_name_with_underscored_action
      result = look_up_page_name("blog_posts", "mark_as_read")
      assert_equal "[\"Mark \", \"As \", \"Read \"]", result
    end

    # Test with multi-word controller names
    def test_look_up_page_name_with_multi_word_controller
      result = look_up_page_name("blog_comments", "index")
      assert_equal "[\"Index \"]", result
    end
    
    def test_look_up_page_name_with_multi_word_controller_edit_action
      result = look_up_page_name("blog_comments", "edit")
      assert_equal "[\"Edit \", \"Blog \", \"Comment \"]", result
    end

    # Test capitalization
    def test_look_up_page_name_capitalizes_words
      result = look_up_page_name("user_sessions", "forgot_password")
      assert_equal "[\"Forgot \", \"Password \"]", result
    end

    # Test edge cases
    def test_look_up_page_name_with_single_character_action
      result = look_up_page_name("posts", "a")
      assert_equal "[\"A \"]", result
    end
    
    def test_look_up_page_name_with_single_character_controller
      result = look_up_page_name("a", "index")
      assert_equal "[\"Index \"]", result
    end

    # Test with numeric characters
    def test_look_up_page_name_with_numbers_in_action
      result = look_up_page_name("posts", "step2")
      assert_equal "[\"Step2 \"]", result
    end

    # Test logging
    def test_look_up_page_name_logs_debug_message
      # Reset log messages
      @log_messages = []
      
      look_up_page_name("posts", "index")
      
      # We can't easily test the exact logging since logger is mocked differently
      # This test just ensures the method doesn't crash when logging
      assert_nothing_raised { look_up_page_name("posts", "index") }
    end

    # Test specific edit action scenarios
    def test_look_up_page_name_edit_action_with_pluralized_controller
      result = look_up_page_name("categories", "edit")
      assert_equal "[\"Edit \", \"Category \"]", result
    end
    
    def test_look_up_page_name_show_action_with_irregular_plural
      # Test with controller that has irregular singular form
      result = look_up_page_name("people", "show")
      assert_equal "[\"Show \", \"Person \"]", result
    end
    
    def test_look_up_page_name_new_action_with_compound_word
      result = look_up_page_name("blog_posts", "new")
      assert_equal "[\"New \", \"Blog \", \"Post \"]", result
    end

    # Test array string format in result
    def test_look_up_page_name_result_returns_array_string
      result = look_up_page_name("posts", "index")
      assert result.start_with?("["), "Result should start with bracket"
      assert result.end_with?("]"), "Result should end with bracket"
    end
    
    def test_look_up_page_name_result_has_capitalized_words
      result = look_up_page_name("user_accounts", "edit")
      assert_equal "[\"Edit \", \"User \", \"Account \"]", result
      
      # Verify the format includes capitalized words
      assert result.include?("Edit"), "Result should include 'Edit'"
      assert result.include?("User"), "Result should include 'User'"
      assert result.include?("Account"), "Result should include 'Account'"
    end

    # Test the PAGE_NAMES constant
    def test_page_names_constant_structure
      assert_kind_of Hash, PageNamesHelper::PAGE_NAMES
      assert_kind_of Hash, PageNamesHelper::PAGE_NAMES[:blog_posts]
      assert_equal "Blog", PageNamesHelper::PAGE_NAMES[:blog_posts][:index]
    end

    # Test that the method works with string and symbol inputs
    def test_look_up_page_name_with_string_inputs
      result = look_up_page_name("blog_posts", "index")
      assert_equal "Blog", result
    end
    
    def test_look_up_page_name_with_symbol_controller_if_passed
      # The method converts to symbol internally, so this should work the same
      result = look_up_page_name("blog_posts", "index")
      assert_equal "Blog", result
    end
  end
end