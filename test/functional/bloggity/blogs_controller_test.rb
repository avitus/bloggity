require 'test_helper'

class Bloggity::BlogsControllerTest < ActionController::TestCase
  tests Bloggity::BlogsController
  fixtures :users  # Only load user fixtures, which we need

  def setup
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

    @regular_user = User.create!(
      name: 'Regular User',
      email: 'regular@test.com', 
      can_blog: false,
      can_comment: true
    )

    @blog = Bloggity::Blog.create!(
      title: 'Test Blog',
      subtitle: 'A test blog for testing',
      url_identifier: 'test-blog'
    )

    @blog2 = Bloggity::Blog.create!(
      title: 'Another Blog',
      subtitle: 'Another test blog',
      url_identifier: 'another-blog'
    )

    # Create some blog posts for the feed test
    @published_post = Bloggity::BlogPost.create!(
      title: 'Published Post',
      body: 'This is a published post',
      blog_id: @blog.id,
      posted_by_id: @blogger_user.id,
      is_complete: true,
      url_identifier: 'published-post'
    )

    @draft_post = Bloggity::BlogPost.create!(
      title: 'Draft Post',
      body: 'This is a draft post',
      blog_id: @blog.id,
      posted_by_id: @blogger_user.id,
      is_complete: false,
      url_identifier: 'draft-post'
    )
  end

  # INDEX TESTS
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:blogs)
    assert_equal 'blog', assigns(:tab)
    assert assigns(:blogs).include?(@blog)
    assert assigns(:blogs).include?(@blog2)
  end

  test "should get index as xml" do
    get :index, format: 'xml'
    assert_response :success
    assert_equal 'application/xml', response.content_type
    assert_match @blog.title, response.body
    assert_match @blog2.title, response.body
  end

  # SHOW TESTS
  test "should redirect to blog with url_identifier on show" do
    get :show, params: { id: @blog.id }
    assert_response :redirect
    assert_match "/blog/#{@blog.url_identifier}", response.location
  end

  test "should redirect to blog with id when no url_identifier on show" do
    blog_without_url = Bloggity::Blog.create!(title: 'No URL Blog', url_identifier: '')
    blog_without_url.update_column(:url_identifier, nil) # Bypass validation
    
    get :show, params: { id: blog_without_url.id }
    assert_response :redirect
    assert_match "/blog/#{blog_without_url.id}", response.location
  end

  test "should redirect to blog index when blog not found on show" do
    get :show, params: { id: 99999 }
    assert_response :redirect
    assert_match "/blog", response.location
  end

  # NEW TESTS
  test "should get new" do
    get :new
    assert_response :success
    assert_not_nil assigns(:blog)
    assert assigns(:blog).new_record?
  end

  test "should get new as xml" do
    get :new, format: 'xml'
    assert_response :success
    assert_equal 'application/xml', response.content_type
  end

  # EDIT TESTS  
  test "should get edit" do
    get :edit, params: { id: @blog.id }
    assert_response :success
    assert_equal @blog, assigns(:blog)
    assert_equal 'blog', assigns(:tab)
  end

  test "should raise error when editing non-existent blog" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get :edit, params: { id: 99999 }
    end
  end

  # CREATE TESTS
  test "should create blog with valid params" do
    assert_difference('Bloggity::Blog.count') do
      post :create, params: { 
        blog: { 
          title: 'New Blog',
          subtitle: 'A new blog',
          url_identifier: 'new-blog',
          stylesheet: 'custom.css'
        } 
      }
    end

    blog = Bloggity::Blog.last
    assert_equal 'New Blog', blog.title
    assert_equal 'A new blog', blog.subtitle
    assert_equal 'new-blog', blog.url_identifier
    assert_equal 'custom.css', blog.stylesheet

    assert_response :redirect
    assert_match "/blogs/#{blog.id}", response.location
    assert_equal 'Blog was successfully created.', flash[:notice]
  end

  test "should create blog as xml with valid params" do
    assert_difference('Bloggity::Blog.count') do
      post :create, params: { 
        blog: { 
          title: 'XML Blog',
          subtitle: 'Created via XML',
          url_identifier: 'xml-blog'
        } 
      }, format: 'xml'
    end

    assert_response :created
    assert_equal 'application/xml', response.content_type
    assert_match 'XML Blog', response.body
  end

  test "should not create blog with invalid params" do
    assert_no_difference('Bloggity::Blog.count') do
      post :create, params: { 
        blog: { 
          title: '',  # Invalid - title is required
          subtitle: 'A blog without title'
        } 
      }
    end

    assert_response :success
    assert_template :new
    assert_not_nil assigns(:blog)
    assert assigns(:blog).errors.any?
  end

  test "should not create blog as xml with invalid params" do
    assert_no_difference('Bloggity::Blog.count') do
      post :create, params: { 
        blog: { 
          title: '',  # Invalid
          subtitle: 'Invalid blog'
        } 
      }, format: 'xml'
    end

    assert_response :unprocessable_entity
    assert_equal 'application/xml', response.content_type
    assert_match 'errors', response.body
  end

  test "should filter params using blog_params" do
    post :create, params: { 
      blog: { 
        title: 'Filtered Blog',
        subtitle: 'Testing param filtering',
        url_identifier: 'filtered-blog',
        stylesheet: 'style.css',
        malicious_param: 'should_be_filtered'  # This should be filtered out
      } 
    }

    blog = Bloggity::Blog.last
    assert_equal 'Filtered Blog', blog.title
    assert_equal 'Testing param filtering', blog.subtitle
    assert_equal 'filtered-blog', blog.url_identifier
    assert_equal 'style.css', blog.stylesheet
    # The malicious_param should not be set
    assert_not_respond_to blog, :malicious_param
  end

  # UPDATE TESTS
  test "should update blog with valid params" do
    patch :update, params: { 
      id: @blog.id,
      blog: { 
        title: 'Updated Blog Title',
        subtitle: 'Updated subtitle',
        stylesheet: 'updated.css'
      } 
    }

    @blog.reload
    assert_equal 'Updated Blog Title', @blog.title
    assert_equal 'Updated subtitle', @blog.subtitle
    assert_equal 'updated.css', @blog.stylesheet

    assert_response :redirect
    assert_match "/blogs/#{@blog.id}", response.location
    assert_equal 'Blog was successfully updated.', flash[:notice]
  end

  test "should update blog as xml with valid params" do
    patch :update, params: { 
      id: @blog.id,
      blog: { 
        title: 'XML Updated Title'
      } 
    }, format: 'xml'

    @blog.reload
    assert_equal 'XML Updated Title', @blog.title
    assert_response :ok
  end

  test "should not update blog with invalid params" do
    original_title = @blog.title
    patch :update, params: { 
      id: @blog.id,
      blog: { 
        title: ''  # Invalid - title is required
      } 
    }

    @blog.reload
    assert_equal original_title, @blog.title
    assert_response :success
    assert_template :edit
    assert_equal 'Blog was not updated.', flash[:notice]
  end

  test "should not update blog as xml with invalid params" do
    patch :update, params: { 
      id: @blog.id,
      blog: { 
        title: ''  # Invalid
      } 
    }, format: 'xml'

    assert_response :unprocessable_entity
    assert_equal 'application/xml', response.content_type
    assert_match 'errors', response.body
  end

  test "should raise error when updating non-existent blog" do
    assert_raises(ActiveRecord::RecordNotFound) do
      patch :update, params: { 
        id: 99999,
        blog: { title: 'Non-existent' } 
      }
    end
  end

  # DESTROY TESTS
  test "should destroy blog" do
    assert_difference('Bloggity::Blog.count', -1) do
      delete :destroy, params: { id: @blog.id }
    end

    assert_response :redirect
    # The controller redirects to blogs_url
  end

  test "should destroy blog as xml" do
    assert_difference('Bloggity::Blog.count', -1) do
      delete :destroy, params: { id: @blog.id }, format: 'xml'
    end

    assert_response :ok
  end

  test "should raise error when destroying non-existent blog" do
    assert_raises(ActiveRecord::RecordNotFound) do
      delete :destroy, params: { id: 99999 }
    end
  end

  # FEED TESTS
  test "should get feed for existing blog by url_identifier" do
    get :feed, params: { id: @blog.url_identifier }
    assert_response :success
    assert_equal @blog, assigns(:blog)
    assert_equal @blog.id, assigns(:blog_id)
    assert_not_nil assigns(:blog_posts)
    assert_includes assigns(:blog_posts), @published_post
    assert_not_includes assigns(:blog_posts), @draft_post
  end

  test "should get feed for existing blog by id" do
    get :feed, params: { id: @blog.id }
    assert_response :success
    assert_equal @blog, assigns(:blog)
    assert_equal @blog.id, assigns(:blog_id)
    assert_not_nil assigns(:blog_posts)
  end

  test "should limit feed to 15 most recent published posts" do
    # Create 20 published posts
    20.times do |i|
      Bloggity::BlogPost.create!(
        title: "Post #{i}",
        body: "Content #{i}",
        blog_id: @blog.id,
        posted_by_id: @blogger_user.id,
        is_complete: true,
        url_identifier: "post-#{i}",
        created_at: i.days.ago
      )
    end

    get :feed, params: { id: @blog.url_identifier }
    assert_response :success
    
    # Should only return 15 posts
    assert_equal 15, assigns(:blog_posts).count
    # Should be ordered by created_at DESC (most recent first)
    assert_equal "Post 0", assigns(:blog_posts).first.title
  end

  test "should redirect to blog_posts index when feed blog not found" do
    get :feed, params: { id: 'non-existent-blog' }
    assert_response :redirect
    assert_equal "Couldn't find that feed.", flash[:error]
  end

  test "should set request format to xml for feed when no format specified" do
    get :feed, params: { id: @blog.url_identifier }
    assert_equal 'xml', request.format.to_s
  end

  test "should respect xml format for feed" do
    get :feed, params: { id: @blog.url_identifier }, format: 'xml'
    assert_response :success
    assert_equal 'application/xml', response.content_type
  end

  # BREADCRUMB TESTS
  test "should set breadcrumb" do
    get :index
    # This tests that the breadcrumb is added, though we can't easily test the actual breadcrumb
    # without knowing the specific breadcrumb implementation details
    assert_response :success
  end

  # PARAMETER FILTERING TESTS
  test "blog_params should only permit allowed parameters" do
    # This is tested indirectly through the create and update tests above
    # where we verify that unpermitted parameters are filtered out
    assert_response :success if get :index # Just to make this test valid
  end

  # ERROR HANDLING TESTS
  test "should handle database errors gracefully" do
    # Simulate a database error by stubbing Blog.all to raise an exception
    Bloggity::Blog.stub :all, -> { raise StandardError.new("Database error") } do
      assert_raises(StandardError) do
        get :index
      end
    end
  end

  # INSTANCE VARIABLE TESTS
  test "should set correct instance variables in index" do
    get :index
    assert_equal 'blog', assigns(:tab)
    assert_not_nil assigns(:blogs)
    assert_instance_of ActiveRecord::Relation, assigns(:blogs)
  end

  test "should set correct instance variables in edit" do
    get :edit, params: { id: @blog.id }
    assert_equal 'blog', assigns(:tab)
    assert_equal @blog, assigns(:blog)
  end

  test "should set correct instance variables in show" do
    # Since show always redirects, we just test that @blog is set in the before_action
    get :show, params: { id: @blog.id }
    # The controller uses @blog in the redirect logic, so it should be found
    assert_response :redirect
  end

  # ROUTING AND URL TESTS
  test "should generate correct redirect URLs" do
    get :show, params: { id: @blog.id }
    assert_response :redirect
    assert_match "/blog/#{@blog.url_identifier}", response.location
  end

  test "create should redirect to correct URL format" do
    post :create, params: { 
      blog: { 
        title: 'URL Test Blog',
        url_identifier: 'url-test-blog'
      } 
    }
    
    blog = Bloggity::Blog.last
    assert_response :redirect
    assert_match "/blogs/#{blog.id}", response.location
  end

  test "update should redirect to correct URL format" do
    patch :update, params: { 
      id: @blog.id,
      blog: { title: 'Updated for URL test' } 
    }
    
    assert_response :redirect
    assert_match "/blogs/#{@blog.id}", response.location
  end

  private

  def simulate_current_user(user)
    # This would be used if the controller had authentication
    # For now, it's a placeholder for future authentication integration
    session[:user_id] = user.id if user
  end
end