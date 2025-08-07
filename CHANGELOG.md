# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - Phase 1 Security Fixes

### Security
- **CRITICAL**: Fixed XSS vulnerability in blog post body rendering by replacing `.html_safe` with `sanitize()` helper
- **CRITICAL**: Fixed XSS vulnerability in comment display by using `simple_format(strip_tags())` for comment content
- **IMPORTANT**: Implemented proper Strong Parameters across all controllers:
  - BlogPostsController: Added `blog_post_params` and `blog_asset_params` methods
  - BlogCommentsController: Fixed incorrect `params.permit()` usage with proper `params.require(:blog_comment).permit()`
  - BlogCategoriesController: Added `blog_category_params` method
  - BlogsController: Added `blog_params` method
- **IMPORTANT**: Updated all gem dependencies from Rails 3.2.8 to Rails 7.1.5.1, addressing numerous security vulnerabilities:
  - Rails: 3.2.8 → 7.1.5.1
  - Rack: 1.4.1 → 3.2.0
  - jQuery-rails: 2.1.3 → 4.6.0
  - All other dependencies updated to latest secure versions
- Fixed XSS vulnerability in category names using `strip_tags()`
- Fixed XSS vulnerability in tag names using `strip_tags()` with `safe_join()`
- Replaced string interpolation with `.html_safe` in RSS feed link with block syntax
- **NOTE**: Preserved obfuscated JavaScript in blog_comments/_new.html.erb as it serves as anti-spam protection

### Changed
- Updated Gemfile source from HTTP to HTTPS for rubygems.org
- Replaced deprecated ActiveRecord finder methods in controllers
- Updated all controllers to follow Rails conventions for Strong Parameters

### Technical Debt
- Tests currently fail due to Rails 7 incompatibilities (to be addressed in Phase 2)
- Dummy application requires updates for Rails 7 compatibility

## [0.2.27] - Previous Release

### Changed
- Upgraded Bloggity for Rails 5.1 support
- Fixed problems with strong parameters
- Handle blog comment params
- Require Rails 5