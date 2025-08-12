require 'test_helper'

module Bloggity
  class UrlHelperTest < ActionView::TestCase
    include UrlHelper
    
    def setup
      @blog = Blog.create!(
        id: 1,
        title: "Test Blog",
        url_identifier: "test-blog"
      )
      
      @another_blog = Blog.create!(
        id: 2,
        title: "Another Blog", 
        url_identifier: "another-blog"
      )
      
      @blog_post = BlogPost.new(
        id: 1,
        title: "Test Post",
        url_identifier: "test-post",
        blog_id: @blog.id,
        body: "Test content",
        posted_by_id: 1,
        is_complete: true
      )
      @blog_post.blog = @blog
      @blog_post.save!
      
      @another_blog_post = BlogPost.new(
        id: 2,
        title: "Another Post",
        url_identifier: "another-post", 
        blog_id: @another_blog.id,
        body: "Another test content",
        posted_by_id: 1,
        is_complete: true
      )
      @another_blog_post.blog = @another_blog
      @another_blog_post.save!
    end
    
    def teardown
      BlogPost.destroy_all
      Blog.destroy_all
    end

    # Tests for blog_named_link with different actions

    def test_blog_named_link_with_quest_action
      # Mock DOMAIN_NAME constant if it exists, or define it
      begin
        original_domain = DOMAIN_NAME
      rescue NameError
        Object.const_set(:DOMAIN_NAME, "https://example.com")
      end
      
      result = blog_named_link(@blog_post, :quest)
      expected = "https://example.com/blog/test-blog/test-post"
      assert_equal expected, result
      
      # Clean up constant if we defined it
      unless defined?(original_domain)
        Object.send(:remove_const, :DOMAIN_NAME) if defined?(DOMAIN_NAME)
      end
    end
    
    def test_blog_named_link_with_show_action
      result = blog_named_link(@blog_post, :show)
      expected = "/blog/test-blog/test-post"
      assert_equal expected, result
    end
    
    def test_blog_named_link_with_show_action_default
      # :show is the default action
      result = blog_named_link(@blog_post)
      expected = "/blog/test-blog/test-post"
      assert_equal expected, result
    end
    
    def test_blog_named_link_with_list_action
      result = blog_named_link(@blog_post, :list, page: 2)
      expected = "/blog/test-blog/test-post?page=2"
      assert_equal expected, result
    end
    
    def test_blog_named_link_with_list_action_no_page
      result = blog_named_link(@blog_post, :list)
      expected = "/blog/test-blog/test-post?page="
      assert_equal expected, result
    end
    
    def test_blog_named_link_with_index_action
      result = blog_named_link(@blog_post, :index, blog: @blog)
      expected = "/blog/test-blog"
      assert_equal expected, result
    end
    
    def test_blog_named_link_with_index_action_different_blog
      result = blog_named_link(@blog_post, :index, blog: @another_blog)
      expected = "/blog/another-blog"
      assert_equal expected, result
    end
    
    def test_blog_named_link_with_feed_action
      result = blog_named_link(@blog_post, :feed, blog: @blog)
      expected = { controller: 'blogs', id: @blog.id, action: :feed }
      assert_equal expected, result
    end
    
    def test_blog_named_link_with_feed_action_different_blog
      result = blog_named_link(@blog_post, :feed, blog: @another_blog)
      expected = { controller: 'blogs', id: @another_blog.id, action: :feed }
      assert_equal expected, result
    end

    # Tests for other actions (edit, new, etc.)
    def test_blog_named_link_with_edit_action
      result = blog_named_link(@blog_post, :edit)
      expected = { 
        controller: 'blog_posts', 
        action: :edit, 
        blog_id: @blog.id, 
        id: @blog_post 
      }
      assert_equal expected, result
    end
    
    def test_blog_named_link_with_edit_action_custom_blog
      result = blog_named_link(@blog_post, :edit, blog: @another_blog)
      expected = { 
        controller: 'blog_posts', 
        action: :edit, 
        blog_id: @another_blog.id, 
        id: @blog_post 
      }
      assert_equal expected, result
    end
    
    def test_blog_named_link_with_new_action
      result = blog_named_link(@blog_post, :new)
      expected = { 
        controller: 'blog_posts', 
        action: :new, 
        blog_id: @blog.id, 
        id: @blog_post 
      }
      assert_equal expected, result
    end
    
    def test_blog_named_link_with_destroy_action
      result = blog_named_link(@blog_post, :destroy)
      expected = { 
        controller: 'blog_posts', 
        action: :destroy, 
        blog_id: @blog.id, 
        id: @blog_post 
      }
      assert_equal expected, result
    end
    
    def test_blog_named_link_with_custom_action
      result = blog_named_link(@blog_post, :custom_action)
      expected = { 
        controller: 'blog_posts', 
        action: :custom_action, 
        blog_id: @blog.id, 
        id: @blog_post 
      }
      assert_equal expected, result
    end

    # Tests with different blog posts
    def test_blog_named_link_with_different_blog_post
      result = blog_named_link(@another_blog_post, :show)
      expected = "/blog/another-blog/another-post"
      assert_equal expected, result
    end
    
    def test_blog_named_link_with_different_blog_post_edit
      result = blog_named_link(@another_blog_post, :edit)
      expected = { 
        controller: 'blog_posts', 
        action: :edit, 
        blog_id: @another_blog.id, 
        id: @another_blog_post 
      }
      assert_equal expected, result
    end

    # Tests with nil blog_post
    def test_blog_named_link_with_nil_blog_post
      result = blog_named_link(nil)
      assert_equal "/blog", result
    end
    
    def test_blog_named_link_with_nil_blog_post_and_action
      result = blog_named_link(nil, :show)
      assert_equal "/blog", result
    end
    
    def test_blog_named_link_with_nil_blog_post_and_options
      result = blog_named_link(nil, :edit, blog: @blog)
      assert_equal "/blog", result
    end

    # Tests for URL identifier handling
    def test_blog_named_link_handles_special_characters_in_url_identifier
      special_blog = Blog.create!(
        title: "Special Blog",
        url_identifier: "special-blog-with-chars"
      )
      
      special_post = BlogPost.new(
        title: "Special Post",
        url_identifier: "special-post-with-chars",
        blog_id: special_blog.id,
        body: "Special content",
        posted_by_id: 1,
        is_complete: true
      )
      special_post.blog = special_blog
      special_post.save!
      
      result = blog_named_link(special_post, :show)
      expected = "/blog/special-blog-with-chars/special-post-with-chars"
      assert_equal expected, result
    end

    # Tests for options handling
    def test_blog_named_link_ignores_unused_options_for_show
      result = blog_named_link(@blog_post, :show, unused_option: "ignored")
      expected = "/blog/test-blog/test-post"
      assert_equal expected, result
    end
    
    def test_blog_named_link_uses_page_option_for_list
      result = blog_named_link(@blog_post, :list, page: 5, unused_option: "ignored")
      expected = "/blog/test-blog/test-post?page=5"
      assert_equal expected, result
    end
    
    def test_blog_named_link_uses_blog_option_for_index
      result = blog_named_link(@blog_post, :index, blog: @another_blog, unused_option: "ignored")
      expected = "/blog/another-blog"
      assert_equal expected, result
    end
    
    def test_blog_named_link_uses_blog_option_for_edit
      result = blog_named_link(@blog_post, :edit, blog: @another_blog)
      expected = { 
        controller: 'blog_posts', 
        action: :edit, 
        blog_id: @another_blog.id, 
        id: @blog_post 
      }
      assert_equal expected, result
    end

    # Tests for edge cases
    def test_blog_named_link_with_empty_string_action
      result = blog_named_link(@blog_post, "")
      expected = { 
        controller: 'blog_posts', 
        action: "", 
        blog_id: @blog.id, 
        id: @blog_post 
      }
      assert_equal expected, result
    end
    
    def test_blog_named_link_with_symbol_action
      result = blog_named_link(@blog_post, :show)
      expected = "/blog/test-blog/test-post"
      assert_equal expected, result
    end
    
    def test_blog_named_link_with_string_action
      result = blog_named_link(@blog_post, "show")
      expected = { 
        controller: 'blog_posts', 
        action: "show", 
        blog_id: @blog.id, 
        id: @blog_post 
      }
      assert_equal expected, result
    end

    # Test quest action without DOMAIN_NAME constant
    def test_blog_named_link_quest_action_without_domain_name
      # Ensure DOMAIN_NAME is not defined
      if defined?(DOMAIN_NAME)
        original_domain = DOMAIN_NAME
        Object.send(:remove_const, :DOMAIN_NAME)
      end
      
      assert_raises(NameError) do
        blog_named_link(@blog_post, :quest)
      end
      
      # Restore constant if it existed
      if defined?(original_domain)
        Object.const_set(:DOMAIN_NAME, original_domain)
      end
    end

    # Test blog_id fallback
    def test_blog_named_link_uses_blog_post_blog_id_when_no_blog_option
      result = blog_named_link(@blog_post, :edit)
      expected = { 
        controller: 'blog_posts', 
        action: :edit, 
        blog_id: @blog_post.blog_id, 
        id: @blog_post 
      }
      assert_equal expected, result
    end

    # Test with blog_post that has no associated blog object but has blog_id
    def test_blog_named_link_with_blog_id_only
      orphan_post = BlogPost.new(
        id: 99,
        title: "Orphan Post",
        url_identifier: "orphan-post",
        blog_id: @blog.id,
        body: "Orphan content", 
        posted_by_id: 1,
        is_complete: true
      )
      # Don't set the blog association
      
      result = blog_named_link(orphan_post, :edit)
      expected = { 
        controller: 'blog_posts', 
        action: :edit, 
        blog_id: @blog.id, 
        id: orphan_post 
      }
      assert_equal expected, result
    end
  end
end