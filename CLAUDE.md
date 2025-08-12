# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

### Testing
```bash
# Run all tests
rake test

# Run specific test file
ruby -Itest test/unit/bloggity/blog_post_test.rb

# Run functional controller tests
ruby -Itest test/functional/blog_posts_controller_test.rb

# Default rake task runs tests
rake
```

### Development Setup
```bash
# Install dependencies
bundle install

# Update dependencies (be careful with Rails version constraints)
bundle update

# Setup dummy app database
cd test/dummy && rails db:create db:migrate
```

### Active Storage Migration (for existing installations)
```bash
# Install Active Storage
rails active_storage:install

# Run Bloggity migrations
rails db:migrate

# Migrate existing blog assets from attachment_fu/Paperclip
rails blog_assets:migrate_to_active_storage
```

## Architecture Overview

Bloggity is a Rails 7+ Engine that provides complete blog functionality. Key architectural patterns:

1. **Rails Engine Structure**: All code is namespaced under `Bloggity::` and uses `isolate_namespace Bloggity` in lib/bloggity/engine.rb

2. **Core Models** (app/models/bloggity/):
   - `Blog`: Container for posts, handles configuration
   - `BlogPost`: Posts with SEO URLs (via `url_identifier`), draft/publish states
   - `BlogComment`: Comments with moderation support
   - `BlogAsset`: File attachments using Active Storage (migrated from attachment_fu)
   - `BlogCategory`: Post categorization
   - `BlogTag`: Post tagging

3. **Controllers** (app/controllers/bloggity/):
   - All inherit from `Bloggity::ApplicationController`
   - Main controllers: `BlogPostsController`, `BlogsController`, `BlogCommentsController`
   - Support for draft posts viewing (`pending` action)

4. **User Integration**: The engine expects the host app to provide:
   - `User` model with methods: `can_blog?`, `can_comment?`, `blog_display_name`
   - Authentication: `current_user`, `require_login` methods
   - Flash messages: `:notice` and `:error`

5. **URL Pattern**: Posts use SEO-friendly URLs based on title (parameterized as `url_identifier`)

6. **Testing**: Uses a dummy Rails app in test/dummy/ for integration testing with fixtures in test/fixtures/

7. **Asset Storage**: Uses Rails Active Storage for file uploads (images, attachments). Legacy attachment_fu files can be migrated using the provided rake task.

## Important Version Note

Bloggity is designed for Rails 7+ applications (see bloggity.gemspec: `rails >= 7.0`). Key considerations:
- Requires Rails 7.0 or higher
- Uses Active Storage for file uploads (replaces attachment_fu)
- All models inherit from `Bloggity::ApplicationRecord` to handle Rails 7 defaults
- Requires jQuery-rails for legacy JavaScript compatibility
- Uses Kaminari for pagination
- Requires image_processing gem for Active Storage variants

## Key Features to Maintain

- Multi-blog support within single app
- Draft/publish workflow for posts (`is_complete` flag)
- Comment moderation system
- RSS feed generation (app/views/bloggity/blogs/feed.xml.builder)
- Tag and category organization
- SEO-friendly URLs using post titles
- Active Storage integration for file uploads with migration support from legacy systems