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
  s.summary      = "A Rails Blogging Engine"
  s.description  = "A Rails Blogging Engine"

  s.files        = `git ls-files`.split("\n")
  s.require_path = 'lib'  # ALV: not included by default

  s.test_files   = Dir["test/**/*"]

  s.add_dependency "rails", ">= 5.0"
  s.add_dependency "jquery-rails"

  s.add_development_dependency "sqlite3"
end
