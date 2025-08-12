# == Schema Information
# 
# Table name: bloggity_blogs
#
# t.string   "title"
# t.string   "subtitle"
# t.string   "url_identifier"
# t.string   "stylesheet"
# t.string   "feedburner_url"
# t.integer  "category_id"
# t.boolean  "fck_created"
# t.datetime "created_at"
# t.datetime "updated_at"

module Bloggity
  class Blog < ApplicationRecord
    self.table_name = 'bloggity_blogs'
    
    # Associations
    has_many :blog_posts, dependent: :destroy
    belongs_to :category, class_name: 'Bloggity::BlogCategory', optional: true

    # Validations
    validates :title, presence: true
    validates :url_identifier, presence: true, uniqueness: true

    # Callbacks
    before_validation :generate_url_identifier_from_title, if: :url_identifier_blank?
    before_validation :ensure_unique_url_identifier
    before_save :parameterize_url_identifier

    private

    def parameterize_url_identifier
      self.url_identifier = url_identifier.parameterize if url_identifier.present?
    end

    def generate_url_identifier_from_title
      if title.present?
        self.url_identifier = title.parameterize
      end
    end

    def ensure_unique_url_identifier
      return unless url_identifier.present?
      
      base_identifier = url_identifier
      identifier = base_identifier
      counter = 0
      
      while Blog.where(url_identifier: identifier).where.not(id: id || 0).exists?
        counter += 1
        identifier = "#{base_identifier}-#{counter}"
      end
      
      self.url_identifier = identifier
    end

    def url_identifier_blank?
      url_identifier.blank?
    end
  end
end
