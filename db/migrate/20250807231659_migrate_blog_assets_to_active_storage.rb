# Migration to convert existing BlogAsset records from attachment_fu/Paperclip to Active Storage
class MigrateBlogAssetsToActiveStorage < ActiveRecord::Migration[5.0]
  def up
    # Add new columns to blog_assets for Active Storage compatibility
    # We'll keep the existing columns temporarily for backward compatibility
    add_column :bloggity_blog_assets, :migrated_to_active_storage, :boolean, default: false
    
    # This migration is designed to be run after implementing Active Storage in the BlogAsset model
    # It can migrate existing attachment_fu files to Active Storage format
    
    puts "Blog assets migration prepared. Run blog_assets:migrate_to_active_storage rake task after updating models."
  end

  def down
    remove_column :bloggity_blog_assets, :migrated_to_active_storage
  end
end