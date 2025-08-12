class AddTweetedToBlogPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :bloggity_blog_posts, :tweeted, :boolean, default: false
  end
end