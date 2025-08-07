namespace :blog_assets do
  desc "Migrate existing BlogAsset records from attachment_fu/Paperclip to Active Storage"
  task migrate_to_active_storage: :environment do
    puts "Starting migration of BlogAsset records to Active Storage..."
    
    migrated_count = 0
    failed_count = 0
    
    Bloggity::BlogAsset.where(migrated_to_active_storage: [false, nil]).find_each do |asset|
      begin
        # Skip if already has Active Storage attachment
        next if asset.attachment.attached?
        
        # Try to find the old file based on attachment_fu conventions
        old_file_path = find_legacy_file(asset)
        
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
            puts "✓ Migrated BlogAsset ##{asset.id} (#{asset.filename})"
          else
            puts "✗ Failed to attach file for BlogAsset ##{asset.id}"
            failed_count += 1
          end
        else
          puts "✗ Could not find legacy file for BlogAsset ##{asset.id} (#{asset.filename})"
          puts "  Searched: #{old_file_path}" if old_file_path
          failed_count += 1
        end
        
      rescue => e
        puts "✗ Error migrating BlogAsset ##{asset.id}: #{e.message}"
        failed_count += 1
      end
    end
    
    puts "\nMigration complete!"
    puts "Successfully migrated: #{migrated_count} assets"
    puts "Failed: #{failed_count} assets"
    
    if failed_count > 0
      puts "\nNote: Failed assets may have missing source files or other issues."
      puts "You can manually re-upload these assets through the blog interface."
    end
  end
  
  private
  
  def find_legacy_file(asset)
    # Common attachment_fu storage paths
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