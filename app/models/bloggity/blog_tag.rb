# t.string   "name"
# t.integer  "blog_post_id"
# t.datetime "created_at"
# t.datetime "updated_at"

module Bloggity			
	class BlogTag < ActiveRecord::Base
		belongs_to :blog_post
	end
end
