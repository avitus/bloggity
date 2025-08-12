# == Schema Information
# Table name: bloggity_blog_categories
#
# t.string   "name"
# t.integer  "parent_id"
# t.integer  "blog_id"
# t.datetime "created_at"
# t.datetime "updated_at"

module Bloggity		
  class BlogCategory < ApplicationRecord
    self.table_name = 'bloggity_blog_categories'
    
    belongs_to :blog, optional: true
    belongs_to :parent, class_name: 'BlogCategory', optional: true
    has_many :children, class_name: 'BlogCategory', foreign_key: 'parent_id'
    
    validates :name, presence: true
  end
end