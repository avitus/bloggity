# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

### Testing
```bash
# Run all tests
rake test

# Run specific test file
ruby -Itest test/unit/bloggity/blog_post_test.rb

# Default rake task runs tests
rake
```

### Development Setup
```bash
# Install dependencies
bundle install

# Update dependencies (be careful with Rails version constraints)
bundle update
```

## Architecture Overview

Bloggity is a Rails Engine that provides complete blog functionality. Key architectural patterns:

1. **Rails Engine Structure**: All code is namespaced under `Bloggity::` and uses `isolate_namespace Bloggity`

2. **Core Models** (app/models/bloggity/):
   - `Blog`: Container for posts, handles configuration
   - `BlogPost`: Posts with SEO URLs, drafts, tagging
   - `BlogComment`: Moderation-enabled comments
   - `BlogAsset`: File attachment handling

3. **User Integration**: The engine expects the host app to provide:
   - `User` model with methods: `can_blog?`, `can_comment?`, `blog_display_name`
   - Authentication: `current_user`, `require_login` methods
   - Flash messages: `:notice` and `:error`

4. **URL Pattern**: Posts use SEO-friendly URLs based on title (parameterized)

5. **Testing**: Uses a dummy Rails app in test/dummy/ for integration testing

## Important Version Note

The codebase has been upgraded for Rails 5+ but Gemfile.lock still references Rails 3.2.8. When working with dependencies:
- Use the gemspec requirements (Rails >= 5.0)
- Run `bundle update` if you encounter dependency issues

## Key Features to Maintain

- Multi-blog support within single app
- Draft/publish workflow for posts
- Comment moderation system
- RSS feed generation (app/views/bloggity/feed.xml.builder)
- Tag and category organization
- SEO-friendly URLs using post titles