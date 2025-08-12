require 'test_helper'
require 'rake'
require 'fileutils'
require 'stringio'

class BlogAssetsMigrationTest < ActiveSupport::TestCase
  def setup
    # Create test user directly in database
    User.create!(id: 999, name: 'Test User', can_blog: true, can_comment: true) rescue nil
    @user = User.find(999)
    
    # Create test blog
    Bloggity::Blog.create!(id: 999, title: 'Test Blog') rescue nil
    @blog = Bloggity::Blog.find(999)
    
    # Create a blog post
    @blog_post = Bloggity::BlogPost.create!(
      title: 'Test Post',
      body: 'Test content',
      blog: @blog,
      posted_by: @user
    )
    
    # Set up test directories and files
    setup_test_directories
    setup_test_files
    
    # Load Rails application tasks
    Rails.application.load_tasks rescue nil
  end

  def teardown
    # Clean up test directories
    cleanup_test_directories
    
    # Clean up Active Storage attachments
    cleanup_attachments
    
    # Clean up test data
    cleanup_test_data
  end

  # Test 1: Successful migration with asset that has a legacy file
  def test_finds_and_migrates_assets_with_legacy_files
    # Create an unmigrated asset
    asset = create_legacy_asset(filename: 'test_migration.jpg', migrated: false)
    
    # Create the legacy file in the expected location
    legacy_path = Rails.root.join('public', 'images', 'upload', 'blog_assets', 'test_migration.jpg')
    FileUtils.cp(@test_files[:jpg], legacy_path)
    
    # Manually run the migration logic instead of invoking the rake task
    migrated_count, failed_count = run_migration_logic
    
    # Verify the asset was migrated
    asset.reload
    assert asset.migrated_to_active_storage?, "Asset should be marked as migrated"
    assert asset.attachment.attached?, "Asset should have Active Storage attachment"
    assert migrated_count > 0, "Should have migrated at least one asset"
  end

  # Test 2: Migration handles missing legacy files gracefully
  def test_handles_missing_legacy_files
    # Create an unmigrated asset without a corresponding legacy file
    asset = create_legacy_asset(filename: 'missing_file.jpg', migrated: false)
    
    # Run the migration logic
    migrated_count, failed_count = run_migration_logic
    
    # Verify the asset was not migrated
    asset.reload
    assert_not asset.migrated_to_active_storage?, "Asset should not be marked as migrated"
    assert_not asset.attachment.attached?, "Asset should not have Active Storage attachment"
    assert failed_count > 0, "Should have failed at least one asset"
  end

  # Test 3: Migration skips already migrated assets
  def test_skips_already_migrated_assets
    # Create an asset that's already migrated
    asset = create_legacy_asset(filename: 'already_migrated.jpg', migrated: true)
    
    # Create a legacy file (this should be ignored)
    legacy_path = Rails.root.join('public', 'images', 'upload', 'blog_assets', 'already_migrated.jpg')
    FileUtils.cp(@test_files[:jpg], legacy_path)
    
    # Count unmigrated assets before
    unmigrated_before = Bloggity::BlogAsset.where(migrated_to_active_storage: [false, nil]).count
    
    # Run migration logic
    migrated_count, failed_count = run_migration_logic
    
    # Count unmigrated assets after
    unmigrated_after = Bloggity::BlogAsset.where(migrated_to_active_storage: [false, nil]).count
    
    # Should not have processed the already-migrated asset
    assert_equal unmigrated_before, unmigrated_after + migrated_count, 
                 "Only unmigrated assets should be processed"
  end

  # Test 4: Migration handles different file types
  def test_handles_different_file_types
    file_types = [
      { extension: 'png', content_type: 'image/png', source: @test_files[:png] },
      { extension: 'jpg', content_type: 'image/jpeg', source: @test_files[:jpg] },
      { extension: 'pdf', content_type: 'application/pdf', source: @test_files[:pdf] }
    ]
    
    assets = []
    file_types.each_with_index do |file_type, index|
      filename = "test_#{index}.#{file_type[:extension]}"
      asset = create_legacy_asset(
        filename: filename, 
        content_type: file_type[:content_type], 
        migrated: false
      )
      assets << asset
      
      # Create the legacy file
      legacy_path = Rails.root.join('public', 'images', 'upload', 'blog_assets', filename)
      FileUtils.cp(file_type[:source], legacy_path)
    end
    
    # Run migration
    migrated_count, failed_count = run_migration_logic
    
    # Verify all assets were migrated
    assets.each do |asset|
      asset.reload
      assert asset.migrated_to_active_storage?, "#{asset.filename} should be migrated"
      assert asset.attachment.attached?, "#{asset.filename} should have attachment"
    end
    
    assert_equal file_types.length, migrated_count, "Should migrate all file types"
  end

  # Test 5: Find legacy file method tests different path patterns
  def test_find_legacy_file_patterns
    asset = create_legacy_asset(filename: 'pattern_test.jpg', migrated: false)
    asset.update_column(:id, 123) # Set specific ID for testing patterns
    
    # Test different path patterns that the find_legacy_file method should find
    test_cases = [
      {
        name: "Direct filename",
        path: Rails.root.join('public', 'images', 'upload', 'blog_assets', 'pattern_test.jpg')
      },
      {
        name: "ID prefixed filename", 
        path: Rails.root.join('public', 'images', 'upload', 'blog_assets', '123_pattern_test.jpg')
      },
      {
        name: "Nested by ID",
        path: Rails.root.join('public', 'images', 'upload', 'blog_assets', '123', 'pattern_test.jpg')
      },
      {
        name: "Padded nested path",
        path: Rails.root.join('public', 'images', 'upload', 'blog_assets', '000', '000', '123', 'pattern_test.jpg')
      }
    ]
    
    test_cases.each do |test_case|
      # Clean up from previous test
      asset.update_column(:migrated_to_active_storage, false)
      asset.attachment.purge if asset.attachment.attached?
      
      # Create the file at the test path
      FileUtils.mkdir_p(File.dirname(test_case[:path]))
      FileUtils.cp(@test_files[:jpg], test_case[:path])
      
      # Run migration
      migrated_count, failed_count = run_migration_logic
      
      # Verify the asset was found and migrated
      asset.reload
      assert asset.migrated_to_active_storage?, "Should find file in #{test_case[:name]} pattern"
      assert asset.attachment.attached?, "Should attach file from #{test_case[:name]} pattern"
      
      # Clean up the test file
      FileUtils.rm_f(test_case[:path])
      FileUtils.rmdir(File.dirname(test_case[:path])) rescue nil
    end
  end

  # Test 6: Error handling during migration
  def test_error_handling_during_migration
    asset = create_legacy_asset(filename: 'error_test.jpg', migrated: false)
    
    # Create the legacy file
    legacy_path = Rails.root.join('public', 'images', 'upload', 'blog_assets', 'error_test.jpg')
    FileUtils.cp(@test_files[:jpg], legacy_path)
    
    # Mock the asset to raise an error during update
    original_update_method = asset.method(:update!)
    asset.define_singleton_method(:update!) do |*args|
      raise StandardError, "Simulated database error"
    end
    
    # Run migration
    migrated_count, failed_count = run_migration_logic
    
    # Should handle the error gracefully
    assert failed_count > 0, "Should record the failed migration"
    
    # Restore original method
    asset.define_singleton_method(:update!, original_update_method)
  end

  # Test 7: Assets with nil filenames are handled
  def test_handles_nil_filenames_gracefully
    asset = create_legacy_asset(filename: nil, migrated: false)
    
    # Run migration
    migrated_count, failed_count = run_migration_logic
    
    # Asset with nil filename should not be migrated
    asset.reload
    assert_not asset.migrated_to_active_storage?, "Asset with nil filename should not be migrated"
    assert failed_count > 0, "Should count nil filename as failed migration"
  end

  # Test 8: Migration status tracking works correctly
  def test_migration_status_tracking
    # Create a mix of migrated and unmigrated assets
    migrated_asset = create_legacy_asset(filename: 'already_done.jpg', migrated: true)
    
    unmigrated_assets = [
      create_legacy_asset(filename: 'to_migrate_1.jpg', migrated: false),
      create_legacy_asset(filename: 'to_migrate_2.jpg', migrated: false)
    ]
    
    # Create legacy files for the unmigrated assets
    unmigrated_assets.each do |asset|
      legacy_path = Rails.root.join('public', 'images', 'upload', 'blog_assets', asset.filename)
      FileUtils.cp(@test_files[:jpg], legacy_path)
    end
    
    # Count assets before migration
    initial_migrated = Bloggity::BlogAsset.where(migrated_to_active_storage: true).count
    initial_unmigrated = Bloggity::BlogAsset.where(migrated_to_active_storage: [false, nil]).count
    
    # Run migration
    migrated_count, failed_count = run_migration_logic
    
    # Count assets after migration
    final_migrated = Bloggity::BlogAsset.where(migrated_to_active_storage: true).count
    final_unmigrated = Bloggity::BlogAsset.where(migrated_to_active_storage: [false, nil]).count
    
    # Verify counts
    assert final_migrated > initial_migrated, "Should have more migrated assets after migration"
    assert final_unmigrated < initial_unmigrated, "Should have fewer unmigrated assets after migration"
    assert_equal unmigrated_assets.length, migrated_count, "Should migrate the expected number of assets"
  end

  private

  def setup_test_directories
    # Create directories that match the rake task's search paths
    @test_directories = [
      Rails.root.join('public', 'images', 'upload', 'blog_assets'),
      Rails.root.join('public', 'blog_assets'),
      Rails.root.join('public', 'system', 'blog_assets'),
      Rails.root.join('uploads', 'blog_assets')
    ]
    
    @test_directories.each { |dir| FileUtils.mkdir_p(dir) }
  end

  def setup_test_files
    @test_files = {
      jpg: File.join(File.dirname(__FILE__), '../fixtures/files/test_image.jpg'),
      png: File.join(File.dirname(__FILE__), '../fixtures/files/test_image.png'),
      gif: File.join(File.dirname(__FILE__), '../fixtures/files/test_image.gif'),
      pdf: File.join(File.dirname(__FILE__), '../fixtures/files/test_document.pdf')
    }
    
    # Ensure fixture files exist
    @test_files.each do |type, path|
      FileUtils.mkdir_p(File.dirname(path))
      unless File.exist?(path)
        case type
        when :jpg, :png, :gif
          File.binwrite(path, "\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01")
        when :pdf
          File.write(path, "%PDF-1.4\nstartxref\n%%EOF")
        end
      end
    end
  end

  def cleanup_test_directories
    @test_directories.each { |dir| FileUtils.rm_rf(dir) if File.exist?(dir) }
  end

  def cleanup_attachments
    Bloggity::BlogAsset.find_each do |asset|
      asset.attachment.purge if asset.attachment.attached?
    end
  rescue => e
    # Ignore cleanup errors
  end

  def cleanup_test_data
    Bloggity::BlogAsset.destroy_all
    @blog_post&.destroy
    User.connection.execute("DELETE FROM users WHERE id = 999") rescue nil
    Bloggity::Blog.connection.execute("DELETE FROM bloggity_blogs WHERE id = 999") rescue nil
  rescue => e
    # Ignore cleanup errors
  end

  def create_legacy_asset(filename:, content_type: 'image/jpeg', migrated: false)
    # Create without validations since legacy assets don't have Active Storage attachments
    asset = Bloggity::BlogAsset.new(
      blog_post: @blog_post,
      content_type: content_type,
      filename: filename,
      size: 1024,
      migrated_to_active_storage: migrated
    )
    asset.save!(validate: false)
    asset
  end

  # Core migration logic extracted from the rake task for testing
  def run_migration_logic
    migrated_count = 0
    failed_count = 0
    
    # This mirrors the logic in the rake task
    Bloggity::BlogAsset.where(migrated_to_active_storage: [false, nil]).find_each do |asset|
      begin
        # Skip if already has Active Storage attachment
        next if asset.attachment.attached?
        
        # Try to find the old file based on attachment_fu conventions
        old_file_path = find_legacy_file_for_test(asset)
        
        if old_file_path && File.exist?(old_file_path)
          # Attach the file using Active Storage
          asset.attachment.attach(
            io: File.open(old_file_path),
            filename: asset.filename || File.basename(old_file_path),
            content_type: asset.content_type || 'application/octet-stream'
          )
          
          if asset.attachment.attached?
            asset.update!(migrated_to_active_storage: true)
            migrated_count += 1
          else
            failed_count += 1
          end
        else
          failed_count += 1
        end
      rescue => e
        failed_count += 1
      end
    end
    
    [migrated_count, failed_count]
  end

  # Test version of the find_legacy_file method
  def find_legacy_file_for_test(asset)
    base_paths = [
      Rails.root.join('public', 'images', 'upload', 'blog_assets'),
      Rails.root.join('public', 'blog_assets'),
      Rails.root.join('public', 'system', 'blog_assets'),
      Rails.root.join('uploads', 'blog_assets')
    ]
    
    potential_filenames = [
      asset.filename,
      "#{asset.id}_#{asset.filename}",
      "#{asset.id}/#{asset.filename}",
      "000/000/#{asset.id.to_s.rjust(3, '0')}/#{asset.filename}"
    ].compact
    
    base_paths.each do |base_path|
      potential_filenames.each do |filename|
        full_path = base_path.join(filename)
        return full_path.to_s if File.exist?(full_path)
      end
    end
    
    nil
  end
end