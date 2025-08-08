# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - Phase 1 & 2: Security Fixes and Rails 7 Upgrade

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

### Phase 2: Rails 7 Compatibility (Completed)

#### Changed
- **Rails 7 Compatibility**: Fixed all configuration issues in dummy app
  - Removed deprecated `config.assets.enabled`, `config.active_record.whitelist_attributes`, etc.
  - Added `config.load_defaults 7.0` for proper Rails 7 defaults
  - Updated all environment configurations for Rails 7
  - Fixed secret_token → secret_key_base migration

- **ActiveRecord Modernization**: Updated all deprecated query syntax
  - `find(:all)` → `all` or `where()`
  - `find(:first, :conditions => {})` → `find_by()`
  - `count(:conditions => {})` → `where().count`
  - Dynamic finders updated to modern syntax
  - Hash-based association options converted to keyword arguments

- **Active Storage Migration**: Replaced attachment_fu/Paperclip with Active Storage
  - Created migration scripts for existing data
  - Updated BlogAsset model with Active Storage integration
  - Maintained backward compatibility with `public_filename` method
  - Added image variant support (medium: 800x600, thumb: 267x214)
  - Removed 68 legacy attachment_fu files (~3,786 lines)

- **Rails Pattern Updates**: Fixed all deprecation warnings
  - `update_attributes` → `update` (4 instances)
  - `render :text` → `render plain:` (2 instances)
  - `render :action` → `render` with template syntax (4 instances)
  - `Time.now` → `Time.current` for timezone awareness
  - Updated all render calls to modern hash syntax

- **Test Suite Modernization**: Updated for Rails 7 compatibility
  - Fixed circular require warnings
  - Updated test helper configuration
  - Fixed namespace issues in all test files
  - Added Active Storage test configuration
  - Fixed indentation warnings in helpers

### Technical Improvements
- Successfully runs on Rails 7.1.5.1 (upgraded from Rails 3.2.8)
- All gems updated to latest secure versions
- Modern Ruby syntax throughout (hash rockets removed)
- Cleaner, more maintainable codebase
- Ready for cloud storage integration (S3, GCS, Azure)

## [0.2.27] - Previous Release

### Changed
- Upgraded Bloggity for Rails 5.1 support
- Fixed problems with strong parameters
- Handle blog comment params
- Require Rails 5