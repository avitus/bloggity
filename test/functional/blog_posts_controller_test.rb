require 'test_helper'

class BlogPostsControllerTest < ActionController::TestCase
	tests Bloggity::BlogPostsController
	fixtures :all
	
	def test_blog_show_normal
		blog_post = Bloggity::BlogPost.first
		blog_url = "/blog/#{blog_post.blog.url_identifier}/#{blog_post.url_identifier}"
		
		get :show, params: { id: blog_post.url_identifier, blog_url_id_or_id: blog_post.blog.url_identifier }
		assert_response :success
		assert_equal controller.instance_variable_get(:@blog_post), blog_post
		assert_equal controller.instance_variable_get(:@blog_posts).size, Bloggity::BlogPost.where(:blog_id => blog_post.blog_id, :is_complete => true).count
		assert_equal controller.instance_variable_get(:@blog_id), blog_post.blog_id
	end

	def test_blog_show_secondary_index
		blog_post = Bloggity::BlogPost.all[1]
		
		get :index, params: { blog_url_id_or_id: blog_post.blog.url_identifier }
		assert_response :success
		assert_equal controller.instance_variable_get(:@blog_id), blog_post.blog_id
		assert_equal controller.instance_variable_get(:@blog_posts).size, Bloggity::BlogPost.where(:blog_id => blog_post.blog_id, :is_complete => true).count
		assert_equal controller.instance_variable_get(:@blog_posts).first.blog_id, blog_post.blog_id
		assert_nil controller.instance_variable_get(:@blog_post)
	end
	
	def test_blog_no_show_incomplete
		blog_post = Bloggity::BlogPost.find_by(:is_complete => false)
		User.class_eval do
			def can_blog?(blog_id = nil)
				false
			end
		end
		
		get :show, params: { id: blog_post.id, blog_url_id_or_id: blog_post.blog.url_identifier }
		assert_response :redirect
		assert_nil controller.instance_variable_get(:@blog_post)
	end
	
end
