require 'test_helper'

class BlogPostTest < ActiveSupport::TestCase
	fixtures :all
	
	# Test our validations for new blogs
	def test_create
		blog_post = blog_posts(:blog_post_valid_and_posted)
		assert blog_post.valid?
		
		blog_post.blog_id = nil
		assert !blog_post.valid?
		assert blog_post.errors.on(:blog_id)
		
		blog_post = blog_posts(:blog_post_valid_and_posted)
		user = users(:users_001)
		def user.can_blog?(blog_id = nil)
			false
		end
		blog_post.posted_by = user
		assert !blog_post.valid?
		assert blog_post.errors.on(:posted_by_id)
	end
	
	def test_url_identifier
		blog_post = blog_posts(:blog_post_valid_and_posted)
		blog_post.is_complete = false
		blog_post.title = "My first blog"
		blog_post.save
		assert_equal blog_post.url_identifier, "My_first_blog"
		
		blog_post.is_complete = true
		blog_post.title = "My second blog"
		blog_post.save
		assert_equal blog_post.url_identifier, "My_first_blog"
	end
	
	def test_tag_creation
		blog_post = blog_posts(:blog_post_valid_and_posted)
		blog_post.tag_string = "Pony, horsie, doggie"
		blog_post.save
		assert_equal blog_post.tags.size, 3
		
		blog_post.tag_string = "Parrot"
		blog_post.save
		assert_equal blog_post.tags.size, 1
	end

	# Test authorized_to_blog? validation method
	def test_authorized_to_blog_validation
		user = users(:users_001)
		blog_post = blog_posts(:blog_post_valid_and_posted)
		
		# Test with authorized user
		def user.can_blog?(blog_id = nil)
			true
		end
		blog_post.posted_by = user
		assert blog_post.valid?
		
		# Test with unauthorized user
		def user.can_blog?(blog_id = nil)
			false
		end
		blog_post.posted_by = user
		assert !blog_post.valid?
		assert blog_post.errors[:posted_by_id].include?("is not authorized to post to this blog")
	end
	
	def test_authorized_to_blog_with_nil_user
		blog_post = blog_posts(:blog_post_valid_and_posted)
		blog_post.posted_by = nil
		assert !blog_post.valid?
		assert blog_post.errors[:posted_by_id].include?("is not authorized to post to this blog")
	end
	
	# Test save_tags method and tag parsing functionality
	def test_save_tags_creates_tags_from_string
		blog_post = blog_posts(:blog_post_valid_and_posted)
		blog_post.tag_string = "ruby, rails, programming"
		blog_post.save
		
		assert_equal 3, blog_post.tags.count
		tag_names = blog_post.tags.map(&:name)
		assert_includes tag_names, "ruby"
		assert_includes tag_names, "rails"
		assert_includes tag_names, "programming"
	end
	
	def test_save_tags_handles_whitespace_and_empty_tags
		blog_post = blog_posts(:blog_post_valid_and_posted)
		blog_post.tag_string = " ruby , rails,  , programming , "
		blog_post.save
		
		# Should have 3 tags (empty ones are filtered by strip.chomp)
		assert_equal 3, blog_post.tags.count
		tag_names = blog_post.tags.map(&:name)
		assert_includes tag_names, "ruby"
		assert_includes tag_names, "rails" 
		assert_includes tag_names, "programming"
	end
	
	def test_save_tags_replaces_existing_tags
		blog_post = blog_posts(:blog_post_valid_and_posted)
		blog_post.tag_string = "old, tags"
		blog_post.save
		assert_equal 2, blog_post.tags.count
		
		blog_post.tag_string = "new, different, tags"
		blog_post.save
		assert_equal 3, blog_post.tags.count
		tag_names = blog_post.tags.map(&:name)
		assert_includes tag_names, "new"
		assert_includes tag_names, "different"
		assert_includes tag_names, "tags"
		refute_includes tag_names, "old"
	end
	
	def test_save_tags_with_blank_string
		blog_post = blog_posts(:blog_post_valid_and_posted)
		blog_post.tag_string = "ruby, rails"
		blog_post.save
		assert_equal 2, blog_post.tags.count
		
		blog_post.tag_string = ""
		blog_post.save
		# Tags should remain unchanged when tag_string is blank
		assert_equal 2, blog_post.tags.count
		
		blog_post.tag_string = nil
		blog_post.save
		# Tags should remain unchanged when tag_string is nil
		assert_equal 2, blog_post.tags.count
	end
	
	# Test tweet_public_publish method
	def test_tweet_public_publish_creates_tweet_for_new_complete_post
		blog_post = blog_posts(:blog_post_in_draft_mode)
		blog_post.is_complete = true
		blog_post.tweeted = false
		
		blog_post.save
		assert blog_post.tweeted, "Post should be marked as tweeted"
	end
	
	def test_tweet_public_publish_does_not_create_duplicate_tweets
		blog_post = blog_posts(:blog_post_valid_and_posted)
		blog_post.tweeted = true
		original_tweeted_status = blog_post.tweeted
		
		blog_post.save
		assert_equal original_tweeted_status, blog_post.tweeted, "Tweet status should not change for already tweeted post"
	end
	
	def test_tweet_public_publish_does_not_tweet_drafts
		blog_post = blog_posts(:blog_post_in_draft_mode)
		blog_post.is_complete = false
		blog_post.tweeted = false
		
		blog_post.save
		assert !blog_post.tweeted, "Draft post should not be marked as tweeted"
	end
	
	# Test comments relationship and approval functionality
	def test_comments_association
		blog_post = blog_posts(:blog_post_valid_and_posted)
		assert_respond_to blog_post, :comments
		assert_respond_to blog_post, :approved_comments
	end
	
	def test_approved_comments_only_returns_approved
		blog_post = blog_posts(:blog_post_valid_and_posted)
		
		# Create approved and unapproved comments
		approved_comment = Bloggity::BlogComment.create!(
			blog_post: blog_post,
			user_id: 1,
			comment: "Approved comment",
			approved: true
		)
		
		unapproved_comment = Bloggity::BlogComment.create!(
			blog_post: blog_post,
			user_id: 1,
			comment: "Unapproved comment",
			approved: false
		)
		
		assert_includes blog_post.comments, approved_comment
		assert_includes blog_post.comments, unapproved_comment
		assert_includes blog_post.approved_comments, approved_comment
		refute_includes blog_post.approved_comments, unapproved_comment
	end
	
	def test_comments_closed_method
		blog_post = blog_posts(:blog_post_valid_and_posted)
		blog_post.comments_closed = true
		assert blog_post.comments_closed?
		
		blog_post.comments_closed = false
		assert !blog_post.comments_closed?
	end
	
	# Test category association
	def test_category_association
		blog_post = blog_posts(:blog_post_valid_and_posted)
		assert_respond_to blog_post, :category
		
		# Test that category can be nil (optional association)
		blog_post.category = nil
		assert blog_post.valid?
	end
	
	def test_category_assignment
		blog_post = blog_posts(:blog_post_valid_and_posted)
		category = Bloggity::BlogCategory.create!(name: "Test Category", blog_id: 1)
		
		blog_post.category = category
		blog_post.save
		
		assert_equal category, blog_post.reload.category
	end
	
	# Test asset association
	def test_assets_association
		blog_post = blog_posts(:blog_post_valid_and_posted)
		assert_respond_to blog_post, :assets
		assert_kind_of Array, blog_post.assets.to_a
	end
	
	def test_assets_can_be_added
		blog_post = blog_posts(:blog_post_valid_and_posted)
		asset = Bloggity::BlogAsset.create!(
			filename: "test.jpg",
			blog_post: blog_post,
			user_id: 1
		)
		
		assert_includes blog_post.assets, asset
	end
	
	# Test SEO URL generation edge cases
	def test_url_identifier_with_special_characters
		blog_post = blog_posts(:blog_post_in_draft_mode)
		blog_post.title = "My Blog Post with Special Ch@r$!"
		blog_post.save
		
		assert_equal "my-blog-post-with-special-ch-r", blog_post.url_identifier
	end
	
	def test_url_identifier_with_unicode_characters
		blog_post = blog_posts(:blog_post_in_draft_mode)
		blog_post.title = "Café & Résumé"
		blog_post.save
		
		# parameterize should handle unicode appropriately
		assert blog_post.url_identifier.present?
		assert blog_post.url_identifier.match?(/\A[a-z0-9\-]+\z/)
	end
	
	def test_url_identifier_handles_very_long_titles
		blog_post = blog_posts(:blog_post_in_draft_mode)
		long_title = "A" * 300 # Very long title
		blog_post.title = long_title
		blog_post.save
		
		assert blog_post.url_identifier.present?
		assert blog_post.url_identifier.length <= 255 # Should fit in database column
	end
	
	def test_url_identifier_collision_handling
		# Create first post with a title
		blog_post1 = blog_posts(:blog_post_in_draft_mode)
		blog_post1.title = "Duplicate Title"
		blog_post1.is_complete = true
		blog_post1.save
		
		# Create second post with same title
		blog_post2 = Bloggity::BlogPost.new(
			title: "Duplicate Title",
			body: "Some content",
			blog_id: 1,
			posted_by_id: 1,
			is_complete: true
		)
		blog_post2.save
		
		assert_equal "duplicate-title", blog_post1.url_identifier
		assert_equal "duplicate-title--1", blog_post2.url_identifier
	end
	
	def test_url_identifier_not_updated_for_published_posts
		blog_post = blog_posts(:blog_post_valid_and_posted)
		original_url = blog_post.url_identifier
		
		blog_post.title = "Completely New Title"
		blog_post.save
		
		# URL should not change for already published posts
		assert_equal original_url, blog_post.url_identifier
	end
	
	def test_url_identifier_updated_for_draft_posts
		blog_post = blog_posts(:blog_post_in_draft_mode)
		blog_post.title = "New Draft Title"
		blog_post.save
		
		assert_equal "new-draft-title", blog_post.url_identifier
	end
	
	# Test draft vs published state handling (is_complete flag)
	def test_draft_state_behavior
		blog_post = blog_posts(:blog_post_in_draft_mode)
		assert !blog_post.is_complete
		
		# URL identifier should be updatable for drafts
		blog_post.title = "Updated Draft Title"
		blog_post.save
		assert_equal "updated-draft-title", blog_post.url_identifier
	end
	
	def test_published_state_behavior
		blog_post = blog_posts(:blog_post_valid_and_posted)
		assert blog_post.is_complete
		
		# URL identifier should not change for published posts
		original_url = blog_post.url_identifier
		blog_post.title = "New Title"
		blog_post.save
		assert_equal original_url, blog_post.url_identifier
	end
	
	def test_publishing_draft_creates_final_url
		blog_post = blog_posts(:blog_post_in_draft_mode)
		blog_post.title = "Final Title"
		blog_post.is_complete = true
		blog_post.save
		
		final_url = blog_post.url_identifier
		
		# Further title changes should not affect URL
		blog_post.title = "Changed Title"
		blog_post.save
		assert_equal final_url, blog_post.url_identifier
	end
	
	# Test validation requirements
	def test_validates_presence_of_blog_id
		blog_post = blog_posts(:blog_post_valid_and_posted)
		blog_post.blog_id = nil
		assert !blog_post.valid?
		assert blog_post.errors[:blog_id].present?
	end
	
	def test_validates_presence_of_posted_by_id
		blog_post = blog_posts(:blog_post_valid_and_posted)
		blog_post.posted_by_id = nil
		assert !blog_post.valid?
		assert blog_post.errors[:posted_by_id].present?
	end

	# Test belongs_to associations
	def test_belongs_to_blog
		blog_post = blog_posts(:blog_post_valid_and_posted)
		assert_respond_to blog_post, :blog
	end
	
	def test_belongs_to_posted_by_user
		blog_post = blog_posts(:blog_post_valid_and_posted)
		assert_respond_to blog_post, :posted_by
		assert_equal users(:users_001), blog_post.posted_by
	end
	
	# Test feed functionality and queries (as used by blogs controller)
	def test_feed_query_returns_published_posts_only
		# Create both published and draft posts
		published_post = Bloggity::BlogPost.create!(
			title: "Published Post",
			body: "Content",
			blog_id: 1,
			posted_by_id: 1,
			is_complete: true
		)
		
		draft_post = Bloggity::BlogPost.create!(
			title: "Draft Post",
			body: "Content",
			blog_id: 1,
			posted_by_id: 1,
			is_complete: false
		)
		
		# Query like the feed action does
		feed_posts = Bloggity::BlogPost.where(:blog_id => 1, :is_complete => true)
		
		assert_includes feed_posts, published_post
		refute_includes feed_posts, draft_post
	end
	
	def test_feed_query_orders_by_created_at_desc
		# Create posts with different timestamps
		old_post = Bloggity::BlogPost.create!(
			title: "Old Post",
			body: "Content",
			blog_id: 1,
			posted_by_id: 1,
			is_complete: true,
			created_at: 2.days.ago
		)
		
		new_post = Bloggity::BlogPost.create!(
			title: "New Post",
			body: "Content",
			blog_id: 1,
			posted_by_id: 1,
			is_complete: true,
			created_at: 1.day.ago
		)
		
		# Query like the feed action does
		feed_posts = Bloggity::BlogPost.where(:blog_id => 1, :is_complete => true).order("created_at DESC")
		
		assert_equal new_post, feed_posts.first
		assert_equal old_post, feed_posts.last
	end
	
	def test_feed_query_limits_results
		# Create more than 15 posts
		16.times do |i|
			Bloggity::BlogPost.create!(
				title: "Post #{i}",
				body: "Content",
				blog_id: 1,
				posted_by_id: 1,
				is_complete: true
			)
		end
		
		# Query like the feed action does
		feed_posts = Bloggity::BlogPost.where(:blog_id => 1, :is_complete => true).order("created_at DESC").limit(15)
		
		assert_equal 15, feed_posts.count
	end
	
	# Test finder methods and query patterns
	def test_find_by_url_identifier_and_id_pattern
		blog_post = blog_posts(:blog_post_valid_and_posted)
		url_id = blog_post.url_identifier
		post_id = blog_post.id
		
		# Test the pattern used in various controllers for finding posts
		found_by_url = Bloggity::BlogPost.where("url_identifier = ? OR id = ?", url_id, url_id).first
		found_by_id = Bloggity::BlogPost.where("url_identifier = ? OR id = ?", post_id, post_id).first
		
		assert_equal blog_post, found_by_url
		assert_equal blog_post, found_by_id
	end
	
	def test_query_by_blog_id
		blog1_post = blog_posts(:blog_post_valid_and_posted) # blog_id: 1
		blog2_post = blog_posts(:blog_post_valid_and_posted_to_secondary) # blog_id: 2
		
		blog1_posts = Bloggity::BlogPost.where(:blog_id => 1)
		blog2_posts = Bloggity::BlogPost.where(:blog_id => 2)
		
		assert_includes blog1_posts, blog1_post
		refute_includes blog1_posts, blog2_post
		assert_includes blog2_posts, blog2_post
		refute_includes blog2_posts, blog1_post
	end
	
	def test_query_by_completion_status
		published_post = blog_posts(:blog_post_valid_and_posted) # is_complete: true
		draft_post = blog_posts(:blog_post_in_draft_mode) # is_complete: false
		
		published_posts = Bloggity::BlogPost.where(:is_complete => true)
		draft_posts = Bloggity::BlogPost.where(:is_complete => false)
		
		assert_includes published_posts, published_post
		refute_includes published_posts, draft_post
		assert_includes draft_posts, draft_post
		refute_includes draft_posts, published_post
	end
	
	# Test complex queries combining multiple conditions
	def test_complex_query_for_published_posts_in_blog
		# This tests the main query pattern used throughout the application
		results = Bloggity::BlogPost.where(:blog_id => 1, :is_complete => true)
		
		# All results should be from blog 1 and complete
		results.each do |post|
			assert_equal 1, post.blog_id
			assert post.is_complete
		end
	end

end
