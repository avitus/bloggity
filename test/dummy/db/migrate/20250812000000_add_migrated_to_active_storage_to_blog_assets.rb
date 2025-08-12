class AddMigratedToActiveStorageToBlogAssets < ActiveRecord::Migration[7.1]
  def change
    add_column :bloggity_blog_assets, :migrated_to_active_storage, :boolean, default: false
  end
end