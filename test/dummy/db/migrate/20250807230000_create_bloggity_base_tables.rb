class CreateBloggityBaseTables < ActiveRecord::Migration[7.1]
  def change
    create_table :bloggity_blogs do |t|
      t.string   :title
      t.string   :subtitle
      t.string   :url_identifier
      t.string   :stylesheet
      t.string   :feedburner_url
      t.integer  :category_id
      t.boolean  :fck_created
      t.timestamps
    end
    
    add_index :bloggity_blogs, :category_id

    create_table :bloggity_blog_categories do |t|
      t.string   :name
      t.integer  :parent_id
      t.integer  :group_id, default: 0
      t.integer  :blog_id
      t.timestamps
    end
    
    add_index :bloggity_blog_categories, :parent_id
    add_index :bloggity_blog_categories, :group_id

    create_table :bloggity_blog_posts do |t|
      t.string   :title
      t.text     :body
      t.string   :tag_string
      t.integer  :posted_by_id
      t.boolean  :is_complete
      t.string   :url_identifier
      t.boolean  :comments_closed
      t.integer  :category_id
      t.integer  :blog_id, default: 1
      t.boolean  :fck_created
      t.timestamps
    end

    create_table :bloggity_blog_assets do |t|
      t.integer  :blog_post_id
      t.integer  :parent_id
      t.string   :content_type
      t.string   :filename
      t.string   :thumbnail
      t.integer  :size
      t.integer  :width
      t.integer  :height
      t.timestamps
    end

    create_table :bloggity_blog_comments do |t|
      t.integer  :user_id
      t.integer  :blog_post_id
      t.text     :comment
      t.boolean  :approved
      t.timestamps
    end

    create_table :bloggity_blog_tags do |t|
      t.string   :name
      t.integer  :blog_post_id
      t.timestamps
    end
    
    # Create a default blog category
    reversible do |dir|
      dir.up do
        # Only execute this during migration, not during schema load
        if defined?(Bloggity::BlogCategory)
          Bloggity::BlogCategory.create!(name: "Main blog")
        end
      end
    end
  end
end