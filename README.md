[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/avitus/bloggity)

# Bloggity

A comprehensive Rails 7+ blog engine that provides a complete blogging solution with multi-blog support, SEO-friendly URLs, comment moderation, and Active Storage integration.

## Requirements

- Rails 7.0 or higher
- Ruby 3.0 or higher
- Active Storage configured in your Rails application
- ImageProcessing gem for image variants

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bloggity'
```

And then execute:

```bash
$ bundle install
```

Mount the engine in your `config/routes.rb`:

```ruby
mount Bloggity::Engine => "/blog"
```

Install and run the migrations:

```bash
$ rails bloggity:install:migrations
$ rails db:migrate
```

## Usage

### User Integration

Bloggity expects your application to provide a `User` model with these methods:

```ruby
class User < ApplicationRecord
  def can_blog?(blog_id = nil)
    # Return true if user can create/edit blog posts
  end
  
  def can_comment?(blog_id = nil)
    # Return true if user can comment on posts
  end
  
  def blog_display_name
    # Return the name to display for blog posts/comments
    name || email
  end
  
  def blog_comment_auto_approved?(blog_id = nil)
    # Return true if user's comments are auto-approved
  end
end
```

### Authentication

Your ApplicationController should provide:

```ruby
def current_user
  # Return the currently logged-in user
end

def authenticate_user!
  # Redirect to login if not authenticated
end
```

### Creating Your First Blog

Visit `/blog/blogs/new` to create your first blog, then `/blog/blog_posts/new` to create posts.

## Active Storage Migration

Bloggity has been updated to use Rails Active Storage instead of attachment_fu/Paperclip for file attachments.

### For New Installations

Active Storage will be used automatically. Make sure your application has:

1. Active Storage installed: `rails active_storage:install`
2. Image processing gem for variants: Add `gem 'image_processing', '~> 1.0'` to your Gemfile (required for image resizing)
3. Configure storage.yml for your preferred storage service

### For Existing Installations

If you're upgrading from an older version that used attachment_fu/Paperclip:

1. Install Active Storage: `rails active_storage:install`
2. Run the Bloggity migrations: `rails db:migrate`
3. Migrate your existing blog assets: `rails blog_assets:migrate_to_active_storage`

The migration will attempt to find and convert your existing uploaded files to Active Storage format. Any files that can't be found will need to be manually re-uploaded.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
