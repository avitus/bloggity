$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "bloggity/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name         = "bloggity"
  s.version      = Bloggity::VERSION
  s.authors      = ["Andy Vitus"]
  s.email        = ["avitus@gmail.com"]
  s.homepage     = "https://github.com/avitus/bloggity"
  s.summary      = "A comprehensive Rails 7+ blog engine"
  s.description  = "A Rails 7+ engine providing multi-blog support, SEO-friendly URLs, comment moderation, and Active Storage integration"

  s.files        = `git ls-files`.split("\n")
  s.require_path = 'lib'  # ALV: not included by default

  s.test_files   = Dir["test/**/*"]

  s.add_dependency "rails", ">= 7.0"
  s.add_dependency "jquery-rails"
  s.add_dependency "kaminari"
  s.add_dependency "image_processing", "~> 1.0"  # Required for Active Storage variants

  s.add_development_dependency "sqlite3"
end
