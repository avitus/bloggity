class User < ActiveRecord::Base
  def can_blog?(blog_id = nil)
    can_blog
  end
  
  def can_comment?
    can_comment
  end
  
  def blog_display_name
    name
  end
  
  def display_name
    name
  end
  
  def name_or_login
    name || "user#{id}"
  end
  
  def blog_comment_auto_approved?(blog_id = nil)
    # Auto-approve comments for users who can blog
    can_blog?
  end
end