# == Schema Information
# Schema version: 119
#
# Table name: blog_assets
#
#  id           :integer(11)     not null, primary key
#  blog_post_id :integer(11)     
#  parent_id    :integer(11)     
#  content_type :string(255)     # Legacy field - kept for backward compatibility
#  filename     :string(255)     # Legacy field - kept for backward compatibility  
#  thumbnail    :string(255)     # Legacy field - kept for backward compatibility
#  size         :integer(11)     # Legacy field - kept for backward compatibility
#  width        :integer(11)     # Legacy field - kept for backward compatibility
#  height       :integer(11)     # Legacy field - kept for backward compatibility
#  migrated_to_active_storage :boolean # Track migration status
#

module Bloggity
class BlogAsset < ApplicationRecord
  belongs_to :blog_post
	
  # Active Storage attachments
  has_one_attached :attachment
  
  # Active Storage variants for different sizes
  def medium_variant
    return nil unless attachment.attached?
    begin
      attachment.variant(resize_to_limit: [800, 600])
    rescue LoadError => e
      # image_processing gem not available - return original attachment
      Rails.logger.warn "image_processing gem required for image variants. Add 'gem \"image_processing\", \"~> 1.0\"' to your Gemfile. Error: #{e.message}"
      attachment
    end
  end
  
  def thumb_variant  
    return nil unless attachment.attached?
    begin
      attachment.variant(resize_to_limit: [267, 214])
    rescue LoadError => e
      # image_processing gem not available - return original attachment
      Rails.logger.warn "image_processing gem required for image variants. Add 'gem \"image_processing\", \"~> 1.0\"' to your Gemfile. Error: #{e.message}"
      attachment
    end
  end
  
  # Validations for Active Storage
  validate :attachment_presence
  validate :attachment_content_type
  validate :attachment_file_name
  
  # Compatibility methods for existing code
  def public_filename(style = nil)
    return nil unless attachment.attached?
    
    case style
    when :medium, 'medium'
      Rails.application.routes.url_helpers.rails_representation_url(medium_variant, only_path: true)
    when :thumb, 'thumb'  
      Rails.application.routes.url_helpers.rails_representation_url(thumb_variant, only_path: true)
    else
      Rails.application.routes.url_helpers.rails_blob_url(attachment, only_path: true)
    end
  end
  
  # Legacy compatibility - populate legacy fields from Active Storage data
  after_save :update_legacy_fields, if: -> { attachment.attached? && !migrated_to_active_storage? }
  
  private
  
  def attachment_presence
    errors.add(:attachment, "must be present") unless attachment.attached?
  end
  
  def attachment_content_type
    return unless attachment.attached?
    
    allowed_types = [
      "image/jpg",
      "image/jpeg", 
      "image/png",
      "image/gif",
      "application/pdf"
    ]
    
    unless allowed_types.include?(attachment.content_type)
      errors.add(:attachment, "must be a JPG, PNG, GIF, or PDF file")
    end
  end
  
  def attachment_file_name
    return unless attachment.attached?
    
    allowed_extensions = /\.(png|jpe?g|pdf)\z/i
    unless attachment.filename.to_s.match?(allowed_extensions)
      errors.add(:attachment, "must have a PNG, JPG, or PDF extension")
    end
  end
  
  def update_legacy_fields
    if attachment.attached?
      blob = attachment.blob
      update_columns(
        content_type: blob.content_type,
        filename: blob.filename.to_s,
        size: blob.byte_size,
        migrated_to_active_storage: true
      )
    end
  end
		
end
end
