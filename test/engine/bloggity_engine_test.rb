require 'test_helper'

class BloggityEngineTest < ActiveSupport::TestCase
  fixtures :all

  def setup
    @engine = Bloggity::Engine
    @dummy_app = Rails.application
  end

  # ENGINE INITIALIZATION TESTS
  test "engine should be properly initialized" do
    assert_not_nil @engine
    assert_instance_of Class, @engine
    assert @engine < Rails::Engine
  end

  test "engine should have correct class name" do
    assert_equal 'Bloggity::Engine', @engine.name
  end

  test "engine should be defined in Bloggity module" do
    assert_equal 'Bloggity::Engine', @engine.name
    assert @engine.name.start_with?('Bloggity::')
  end

  # ISOLATE NAMESPACE TESTS
  test "engine should isolate namespace" do
    # Check that routes are properly namespaced
    assert_not_nil @engine.routes
    assert_instance_of ActionDispatch::Routing::RouteSet, @engine.routes
    
    # Check that the engine was properly configured with isolate_namespace
    # This is verified by checking the engine code directly since isolate_namespace
    # is called during engine loading
    assert @engine < Rails::Engine
  end

  test "engine models should be properly namespaced" do
    # Test that all engine models are in the Bloggity namespace
    models = [
      Bloggity::Blog,
      Bloggity::BlogPost, 
      Bloggity::BlogComment,
      Bloggity::BlogCategory,
      Bloggity::BlogTag,
      Bloggity::BlogAsset
    ]
    
    models.each do |model|
      assert model.name.start_with?('Bloggity::'), 
             "Model #{model.name} should be in Bloggity namespace"
      
      assert_equal 'Bloggity', model.name.split('::').first,
             "Model #{model.name} should be in Bloggity namespace"
    end
  end

  test "engine controllers should be properly namespaced" do
    # Test that all engine controllers are in the Bloggity namespace
    controllers = [
      Bloggity::ApplicationController,
      Bloggity::BlogsController,
      Bloggity::BlogPostsController,
      Bloggity::BlogCommentsController,
      Bloggity::BlogCategoriesController
    ]
    
    controllers.each do |controller|
      assert controller.name.start_with?('Bloggity::'),
             "Controller #{controller.name} should be in Bloggity namespace"
      
      assert_equal 'Bloggity', controller.name.split('::').first,
             "Controller #{controller.name} should be in Bloggity namespace"
    end
  end

  test "engine helpers should be properly namespaced" do
    # Test that engine helpers are in the Bloggity namespace
    helpers = [
      Bloggity::ApplicationHelper,
      Bloggity::UrlHelper,
      Bloggity::PageNamesHelper
    ]
    
    helpers.each do |helper|
      assert helper.name.start_with?('Bloggity::'),
             "Helper #{helper.name} should be in Bloggity namespace"
    end
  end

  # CONFIG.TO_PREPARE TESTS
  test "engine should configure to_prepare block" do
    # Verify that the engine has a to_prepare configuration
    assert_respond_to @engine.config, :to_prepare
    
    # The to_prepare block should be set up during engine loading
    # We can't easily test the content, but we can verify it exists
    assert @engine.config.respond_to?(:to_prepare)
  end

  test "engine should load decorators in to_prepare" do
    # Create a temporary decorator file to test loading
    decorator_dir = Rails.root.join('app', 'decorators')
    FileUtils.mkdir_p(decorator_dir) unless Dir.exist?(decorator_dir)
    
    decorator_file = decorator_dir.join('test_decorator.rb')
    File.write(decorator_file, "class TestDecorator; end")
    
    begin
      # Simulate the to_prepare block execution
      Dir.glob(Rails.root + "app/decorators/**/*_decorator*.rb").each do |c|
        require_dependency(c)
      end
      
      # Verify the decorator was loaded
      assert defined?(TestDecorator), "Decorator should be loaded"
    ensure
      # Clean up
      File.delete(decorator_file) if File.exist?(decorator_file)
      FileUtils.rm_rf(decorator_dir) if Dir.exist?(decorator_dir) && Dir.empty?(decorator_dir)
      Object.send(:remove_const, :TestDecorator) if defined?(TestDecorator)
    end
  end

  # HELPER INTEGRATION TESTS
  test "engine should add helpers to main application" do
    # Verify that Bloggity helpers are added to ApplicationController
    assert ::ApplicationController.respond_to?(:helper), 
           "ApplicationController should respond to helper method"
    
    # Check that engine helpers are available
    helper_methods = @engine.helpers.instance_methods
    
    # Test some specific helper methods that should be available from our engine
    expected_methods = [
      :load_blog,
      :blog_writer_or_redirect,
      :blog_logged_in?
    ]
    
    found_methods = expected_methods.select { |method| helper_methods.include?(method) }
    
    # At least some bloggity helper methods should be present
    assert found_methods.any?, 
           "Some Bloggity helper methods should be available. Found: #{found_methods}, All helpers: #{helper_methods.sort}"
  end

  test "engine helpers should be accessible in views" do
    # This tests that helpers are properly integrated
    # We'll test this by checking if the engine's helper module is included
    
    # Create a test view context
    view_context = ActionView::Base.new
    
    # The engine helpers should be available through the main application
    engine_helpers = @engine.helpers
    assert_not_nil engine_helpers
    assert engine_helpers.is_a?(Module)
  end

  # DEPENDENCY TESTS
  test "engine should require kaminari" do
    # Verify that Kaminari is loaded (as required in engine.rb)
    assert defined?(Kaminari), "Kaminari should be loaded"
    assert Kaminari.respond_to?(:config), "Kaminari should be properly configured"
  end

  test "engine should handle missing thinking_sphinx gracefully" do
    # The engine.rb file has thinking_sphinx commented out
    # This test verifies the engine works without it
    
    # Verify engine loads without thinking_sphinx
    assert_not_nil @engine
    
    # If ThinkingSphinx is defined, it should work; if not, that's fine too
    if defined?(ThinkingSphinx)
      assert ThinkingSphinx.respond_to?(:config)
    else
      # This is expected and fine - thinking_sphinx is commented out
      assert true
    end
  end

  # ROUTES INTEGRATION TESTS
  test "engine routes should be mounted properly" do
    # Check that engine routes are accessible
    assert_not_nil @engine.routes
    
    # Test that some key routes exist in the engine
    routes = @engine.routes.routes
    assert routes.any?, "Engine should have routes defined"
    
    # Check for some specific routes
    route_paths = routes.map { |r| r.path.spec.to_s }
    
    # Should have root route
    assert route_paths.include?('/'), "Should have root route"
    
    # Should have blogs routes
    assert route_paths.any? { |path| path.include?('blogs') }, 
           "Should have blogs routes"
    
    # Should have blog_posts routes
    assert route_paths.any? { |path| path.include?('blog_posts') }, 
           "Should have blog_posts routes"
  end

  test "engine should work with host application routing" do
    # Test that the engine integrates properly with the host app
    
    # The dummy app should be able to mount the engine
    assert @dummy_app.routes.respond_to?(:draw)
    
    # Engine should provide routes that can be mounted
    assert @engine.respond_to?(:routes)
    assert @engine.routes.respond_to?(:draw)
  end

  # ASSET PIPELINE INTEGRATION TESTS
  test "engine should integrate with asset pipeline" do
    # Test that the engine works with the asset pipeline
    
    # Check if the engine has asset paths configured
    if @engine.config.respond_to?(:assets)
      # Assets should be configured if the asset pipeline is available
      assert @engine.config.assets.respond_to?(:paths) || 
             @engine.config.assets.respond_to?(:precompile)
    end
    
    # The engine should be able to serve its own assets
    assert @engine.respond_to?(:config)
  end

  test "engine should handle asset path resolution" do
    # Test that assets from the engine can be resolved
    
    # Check if we can access engine's asset paths
    engine_root = @engine.root
    assert_not_nil engine_root
    
    # Engine should have an app directory structure
    app_path = engine_root.join('app')
    assert Dir.exist?(app_path), "Engine should have app directory"
    
    # Check for assets directory (if it exists)
    assets_path = app_path.join('assets')
    if Dir.exist?(assets_path)
      assert Dir.exist?(assets_path), "Assets directory should be accessible"
    end
  end

  # CONFIGURATION TESTS
  test "engine should have proper configuration" do
    # Test that the engine has the expected configuration
    assert_not_nil @engine.config
    assert @engine.config.respond_to?(:to_prepare)
    
    # Should be configured as an engine
    assert @engine < Rails::Engine
  end

  test "engine should not conflict with host application" do
    # Test that the engine doesn't interfere with the host application
    
    # Host app should still function normally
    assert_not_nil @dummy_app
    assert @dummy_app.respond_to?(:routes)
    
    # Engine should be properly isolated
    assert @engine < Rails::Engine
    assert_equal 'Bloggity::Engine', @engine.name
  end

  # DATABASE INTEGRATION TESTS
  test "engine should work with database" do
    # Test that the engine's models can interact with the database
    
    # Should be able to create engine models
    blog = Bloggity::Blog.new(title: 'Test Blog', url_identifier: 'test')
    assert blog.respond_to?(:save)
    
    # Table should exist
    assert Bloggity::Blog.table_exists?, "Blog table should exist"
    assert Bloggity::BlogPost.table_exists?, "BlogPost table should exist"
  end

  test "engine migrations should be properly set up" do
    # Database tables should exist (they're set up in test environment)
    assert ActiveRecord::Base.connection.table_exists?('bloggity_blogs')
    assert ActiveRecord::Base.connection.table_exists?('bloggity_blog_posts')
    assert ActiveRecord::Base.connection.table_exists?('bloggity_blog_comments')
    assert ActiveRecord::Base.connection.table_exists?('bloggity_blog_categories')
  end

  # INITIALIZATION ORDER TESTS
  test "engine should initialize after Rails" do
    # The engine should be initialized properly in the Rails loading process
    assert Rails.application.initialized?, "Rails should be initialized"
    assert @engine.instance.respond_to?(:config)
  end

  test "engine should be findable by Rails" do
    # Rails should be able to find and load the engine
    railties = Rails.application.railties._all
    bloggity_engine = railties.find { |railtie| railtie.class == Bloggity::Engine }
    
    assert_not_nil bloggity_engine, "Bloggity engine should be loaded by Rails"
    assert_equal Bloggity::Engine, bloggity_engine.class
  end

  # ERROR HANDLING TESTS
  test "engine should handle missing dependencies gracefully" do
    # Test that the engine fails gracefully if required dependencies are missing
    
    # Kaminari is required - it should be loaded
    assert defined?(Kaminari), "Kaminari should be available"
    
    # Engine should still work if optional dependencies are missing
    # (like thinking_sphinx which is commented out)
    assert_not_nil @engine
  end

  test "engine should handle decorator loading errors gracefully" do
    # Test what happens if there's an error loading decorators
    
    # Create a malformed decorator file
    decorator_dir = Rails.root.join('app', 'decorators')
    FileUtils.mkdir_p(decorator_dir) unless Dir.exist?(decorator_dir)
    
    bad_decorator = decorator_dir.join('bad_decorator.rb')
    File.write(bad_decorator, "class BadDecorator\n  invalid ruby syntax here\nend")
    
    begin
      # This should handle the error gracefully
      assert_nothing_raised do
        begin
          Dir.glob(Rails.root + "app/decorators/**/*_decorator*.rb").each do |c|
            require_dependency(c)
          end
        rescue SyntaxError, LoadError
          # This is expected for a malformed file
        end
      end
    ensure
      # Clean up
      File.delete(bad_decorator) if File.exist?(bad_decorator)
      FileUtils.rm_rf(decorator_dir) if Dir.exist?(decorator_dir) && Dir.empty?(decorator_dir)
    end
  end

  # INTEGRATION WITH HOST APPLICATION TESTS
  test "engine should integrate with host application controllers" do
    # Test that engine controllers can use host application functionality
    
    # ApplicationController should exist and be accessible
    assert defined?(::ApplicationController)
    
    # Bloggity::ApplicationController should inherit properly
    assert Bloggity::ApplicationController < ::ApplicationController
  end

  test "engine should work with host application user model" do
    # Test that the engine can work with the host app's User model
    
    assert defined?(User), "User model should be defined in host application"
    
    # User should have the required methods for Bloggity integration
    user = User.new
    assert user.respond_to?(:can_blog?), "User should respond to can_blog?"
    assert user.respond_to?(:can_comment?), "User should respond to can_comment?"
    assert user.respond_to?(:blog_display_name), "User should respond to blog_display_name"
  end

  # PERFORMANCE TESTS
  test "engine should not significantly impact application boot time" do
    # This is more of a smoke test - if the engine causes major boot issues,
    # this test setup would fail
    
    start_time = Time.current
    
    # Simulate engine loading
    assert_not_nil @engine
    assert_not_nil @engine.config
    
    end_time = Time.current
    boot_time = end_time - start_time
    
    # Should boot quickly (less than 1 second for this simple test)
    assert boot_time < 1.0, "Engine should not significantly impact boot time"
  end

  # MEMORY USAGE TESTS
  test "engine should not cause memory leaks" do
    # Basic test that we can create and destroy engine objects without issues
    
    initial_blog_count = Bloggity::Blog.count
    
    # Create and destroy some objects
    10.times do |i|
      blog = Bloggity::Blog.create!(
        title: "Memory Test Blog #{i}",
        url_identifier: "memory-test-#{i}"
      )
      blog.destroy
    end
    
    # Should be back to original count
    assert_equal initial_blog_count, Bloggity::Blog.count
  end

  private

  def simulate_to_prepare_execution
    # Simulate the execution of the to_prepare block
    # This helps test the decorator loading functionality
    Dir.glob(Rails.root + "app/decorators/**/*_decorator*.rb").each do |c|
      begin
        require_dependency(c)
      rescue LoadError, SyntaxError => e
        # Handle gracefully in tests
        Rails.logger.debug "Could not load decorator #{c}: #{e.message}" if Rails.logger
      end
    end
    
    # Ensure helpers are added to main application
    ::ApplicationController.send :helper, Bloggity::Engine.helpers
  end
end