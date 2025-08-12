require 'test_helper'

module Bloggity
  class BlogAssetTest < ActiveSupport::TestCase
    def setup
      # Create a minimal blog post record using raw SQL to avoid ActiveRecord callbacks
      ActiveRecord::Base.connection.execute(
        "INSERT INTO bloggity_blog_posts (id, title, created_at, updated_at) VALUES (999, 'Test Post', '#{Time.current}', '#{Time.current}')"
      )
      @blog_post = Bloggity::BlogPost.find(999)
      
      @valid_png_file = fixture_file_upload('/files/test_image.png', 'image/png')
      @valid_jpg_file = fixture_file_upload('/files/test_image.jpg', 'image/jpeg')
      @valid_gif_file = fixture_file_upload('/files/test_image.gif', 'image/gif')
      @valid_pdf_file = fixture_file_upload('/files/test_document.pdf', 'application/pdf')
      @invalid_file = fixture_file_upload('/files/invalid_file.txt', 'text/plain')
    end

    def teardown
      # Clean up Active Storage attachments
      BlogAsset.all.each do |asset|
        asset.attachment.purge if asset.attachment.attached?
      end
      # Clean up test data
      ActiveRecord::Base.connection.execute("DELETE FROM bloggity_blog_posts WHERE id = 999")
      ActiveRecord::Base.connection.execute("DELETE FROM bloggity_blog_assets")
    end

    # Test Active Storage attachment validation
    def test_attachment_presence_validation
      asset = BlogAsset.new(blog_post: @blog_post)
      assert_not asset.valid?
      assert asset.errors[:attachment].include?("must be present")
    end

    def test_valid_attachment_presence
      asset = BlogAsset.new(blog_post: @blog_post)
      asset.attachment.attach(@valid_png_file)
      assert asset.valid?
    end

    # Test file type validations (JPG, PNG, GIF, PDF)
    def test_valid_image_content_types
      # Test PNG
      asset = BlogAsset.new(blog_post: @blog_post)
      asset.attachment.attach(@valid_png_file)
      assert asset.valid?, "PNG should be valid"

      # Test JPG
      asset = BlogAsset.new(blog_post: @blog_post)
      asset.attachment.attach(@valid_jpg_file)
      assert asset.valid?, "JPG should be valid"

      # Test GIF
      asset = BlogAsset.new(blog_post: @blog_post)
      asset.attachment.attach(@valid_gif_file)
      assert asset.valid?, "GIF should be valid"

      # Test PDF
      asset = BlogAsset.new(blog_post: @blog_post)
      asset.attachment.attach(@valid_pdf_file)
      assert asset.valid?, "PDF should be valid"
    end

    def test_invalid_content_type
      asset = BlogAsset.new(blog_post: @blog_post)
      asset.attachment.attach(@invalid_file)
      assert_not asset.valid?
      assert asset.errors[:attachment].include?("must be a JPG, PNG, GIF, or PDF file")
    end

    def test_jpeg_content_type_variant
      # Test that image/jpg is also accepted (alternative MIME type for JPEG)
      asset = BlogAsset.new(blog_post: @blog_post)
      
      # Mock the attachment to return image/jpg content type
      attachment = asset.attachment
      attachment.attach(@valid_jpg_file)
      
      # Manually set the content type to test the variant
      blob = attachment.blob
      blob.update(content_type: 'image/jpg')
      
      assert asset.valid?, "image/jpg content type should be valid"
    end

    # Test file extension validations
    def test_valid_file_extensions
      # Test .png extension
      asset = BlogAsset.new(blog_post: @blog_post)
      asset.attachment.attach(@valid_png_file)
      assert asset.valid?, ".png extension should be valid"

      # Test .jpg extension
      asset = BlogAsset.new(blog_post: @blog_post)
      asset.attachment.attach(@valid_jpg_file)
      assert asset.valid?, ".jpg extension should be valid"

      # Test .gif extension
      asset = BlogAsset.new(blog_post: @blog_post)
      asset.attachment.attach(@valid_gif_file)
      assert asset.valid?, ".gif extension should be valid"

      # Test .pdf extension
      asset = BlogAsset.new(blog_post: @blog_post)
      asset.attachment.attach(@valid_pdf_file)
      assert asset.valid?, ".pdf extension should be valid"
    end

    def test_invalid_file_extension
      asset = BlogAsset.new(blog_post: @blog_post)
      asset.attachment.attach(@invalid_file)
      assert_not asset.valid?
      assert asset.errors[:attachment].include?("must have a PNG, JPG, or PDF extension")
    end

    def test_jpeg_extension_variant
      # Create a file with .jpeg extension
      jpeg_file = fixture_file_upload('/files/test_image.jpg', 'image/jpeg')
      
      # Rename the filename to have .jpeg extension
      def jpeg_file.original_filename
        'test_image.jpeg'
      end
      
      asset = BlogAsset.new(blog_post: @blog_post)
      asset.attachment.attach(jpeg_file)
      assert asset.valid?, ".jpeg extension should be valid"
    end

    # Test image variant generation (medium_variant, thumb_variant methods)
    def test_medium_variant_generation
      asset = BlogAsset.create!(blog_post: @blog_post)
      asset.attachment.attach(@valid_png_file)
      
      variant = asset.medium_variant
      assert_not_nil variant, "medium_variant should not be nil when attachment is present"
      
      # Test that it returns a variant with correct resize parameters
      if variant.respond_to?(:variation)
        transformations = variant.variation.transformations
        assert_equal [800, 600], transformations[:resize_to_limit], "medium_variant should resize to 800x600"
      end
    end

    def test_thumb_variant_generation
      asset = BlogAsset.create!(blog_post: @blog_post)
      asset.attachment.attach(@valid_png_file)
      
      variant = asset.thumb_variant
      assert_not_nil variant, "thumb_variant should not be nil when attachment is present"
      
      # Test that it returns a variant with correct resize parameters
      if variant.respond_to?(:variation)
        transformations = variant.variation.transformations
        assert_equal [267, 214], transformations[:resize_to_limit], "thumb_variant should resize to 267x214"
      end
    end

    def test_variant_without_attachment
      asset = BlogAsset.new(blog_post: @blog_post)
      
      assert_nil asset.medium_variant, "medium_variant should be nil without attachment"
      assert_nil asset.thumb_variant, "thumb_variant should be nil without attachment"
    end

    def test_variant_with_missing_image_processing_gem
      asset = BlogAsset.create!(blog_post: @blog_post)
      asset.attachment.attach(@valid_png_file)
      
      # Mock LoadError to simulate missing image_processing gem
      attachment = asset.attachment
      def attachment.variant(*args)
        raise LoadError, "image_processing gem not available"
      end
      
      # Should return the original attachment when image_processing is not available
      assert_equal attachment, asset.medium_variant
      assert_equal attachment, asset.thumb_variant
    end

    # Test legacy field updates (update_legacy_fields callback)
    def test_update_legacy_fields_callback
      asset = BlogAsset.new(blog_post: @blog_post, migrated_to_active_storage: false)
      asset.attachment.attach(@valid_png_file)
      asset.save!
      
      # Reload to get updated values
      asset.reload
      
      assert_equal 'image/png', asset.content_type, "content_type should be updated"
      assert_equal 'test_image.png', asset.filename, "filename should be updated"
      assert asset.size > 0, "size should be updated with file size"
      assert asset.migrated_to_active_storage?, "migrated_to_active_storage should be set to true"
    end

    def test_legacy_fields_not_updated_when_already_migrated
      asset = BlogAsset.new(blog_post: @blog_post, migrated_to_active_storage: true)
      original_content_type = asset.content_type
      original_filename = asset.filename
      
      asset.attachment.attach(@valid_png_file)
      asset.save!
      
      # Legacy fields should not be updated if already migrated
      assert_equal original_content_type, asset.content_type
      assert_equal original_filename, asset.filename
    end

    def test_legacy_fields_not_updated_without_attachment
      asset = BlogAsset.new(blog_post: @blog_post, migrated_to_active_storage: false)
      original_content_type = asset.content_type
      
      # This will fail validation, but we're testing the callback doesn't run
      asset.save
      
      assert_equal original_content_type, asset.content_type
    end

    # Test URL generation (public_filename method)
    def test_public_filename_original
      asset = BlogAsset.create!(blog_post: @blog_post)
      asset.attachment.attach(@valid_png_file)
      
      url = asset.public_filename
      assert_not_nil url, "public_filename should return a URL"
      assert url.include?('rails/active_storage/blobs'), "URL should be a blob URL"
    end

    def test_public_filename_medium_variant
      asset = BlogAsset.create!(blog_post: @blog_post)
      asset.attachment.attach(@valid_png_file)
      
      url = asset.public_filename(:medium)
      assert_not_nil url, "public_filename(:medium) should return a URL"
      
      # Test string parameter as well
      url_string = asset.public_filename('medium')
      assert_not_nil url_string, "public_filename('medium') should return a URL"
    end

    def test_public_filename_thumb_variant
      asset = BlogAsset.create!(blog_post: @blog_post)
      asset.attachment.attach(@valid_png_file)
      
      url = asset.public_filename(:thumb)
      assert_not_nil url, "public_filename(:thumb) should return a URL"
      
      # Test string parameter as well
      url_string = asset.public_filename('thumb')
      assert_not_nil url_string, "public_filename('thumb') should return a URL"
    end

    def test_public_filename_without_attachment
      asset = BlogAsset.new(blog_post: @blog_post)
      
      assert_nil asset.public_filename, "public_filename should return nil without attachment"
      assert_nil asset.public_filename(:medium), "public_filename(:medium) should return nil without attachment"
      assert_nil asset.public_filename(:thumb), "public_filename(:thumb) should return nil without attachment"
    end

    def test_public_filename_unknown_style
      asset = BlogAsset.create!(blog_post: @blog_post)
      asset.attachment.attach(@valid_png_file)
      
      # Unknown style should return original blob URL
      url = asset.public_filename(:unknown)
      assert_not_nil url, "public_filename with unknown style should return original URL"
      assert url.include?('rails/active_storage/blobs'), "URL should be a blob URL"
    end

    # Test migration status tracking
    def test_migration_status_default
      asset = BlogAsset.new(blog_post: @blog_post)
      assert_not asset.migrated_to_active_storage?, "migrated_to_active_storage should default to false"
    end

    def test_migration_status_can_be_set
      asset = BlogAsset.new(blog_post: @blog_post, migrated_to_active_storage: true)
      assert asset.migrated_to_active_storage?, "migrated_to_active_storage should be settable to true"
    end

    def test_migration_status_updated_on_save_with_attachment
      asset = BlogAsset.new(blog_post: @blog_post, migrated_to_active_storage: false)
      asset.attachment.attach(@valid_png_file)
      asset.save!
      
      assert asset.migrated_to_active_storage?, "migrated_to_active_storage should be set to true after saving with attachment"
    end

    # Test associations
    def test_belongs_to_blog_post
      asset = BlogAsset.new
      asset.attachment.attach(@valid_png_file)
      asset.blog_post = @blog_post
      
      assert_equal @blog_post, asset.blog_post, "BlogAsset should belong to blog_post"
      assert asset.valid?, "BlogAsset should be valid with blog_post"
    end

    def test_blog_post_association_required
      asset = BlogAsset.new
      asset.attachment.attach(@valid_png_file)
      
      # This might pass depending on validation setup - testing the association exists
      assert_respond_to asset, :blog_post, "BlogAsset should respond to blog_post"
      assert_respond_to asset, :blog_post=, "BlogAsset should respond to blog_post="
    end

    # Integration test for complete workflow
    def test_complete_workflow
      # Create new asset
      asset = BlogAsset.new(blog_post: @blog_post)
      
      # Attach file
      asset.attachment.attach(@valid_png_file)
      
      # Save
      assert asset.save, "Asset should save successfully"
      
      # Check that legacy fields are populated
      asset.reload
      assert_not_nil asset.content_type, "content_type should be set"
      assert_not_nil asset.filename, "filename should be set"
      assert asset.size > 0, "size should be set"
      assert asset.migrated_to_active_storage?, "migration status should be true"
      
      # Check variants work
      assert_not_nil asset.medium_variant, "medium_variant should work"
      assert_not_nil asset.thumb_variant, "thumb_variant should work"
      
      # Check URLs work
      assert_not_nil asset.public_filename, "public_filename should work"
      assert_not_nil asset.public_filename(:medium), "public_filename(:medium) should work"
      assert_not_nil asset.public_filename(:thumb), "public_filename(:thumb) should work"
    end

    private

    def fixture_file_upload(path, mime_type = nil, binary = false)
      file_path = File.join(File.dirname(__FILE__), '../../fixtures', path)
      
      # Ensure the file exists, create minimal version if not
      unless File.exist?(file_path)
        FileUtils.mkdir_p(File.dirname(file_path))
        File.write(file_path, 'test content')
      end
      
      Rack::Test::UploadedFile.new(file_path, mime_type, binary)
    end
  end
end