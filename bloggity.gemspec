# -*- encoding: utf-8 -*-
require File.expand_path('../lib/bloggity/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["¨Andy¨"]
  gem.email         = ["avitus@gmail.com"]
  gem.description   = %q{A simple Rails 3.2 blog}
  gem.summary       = %q{A simple Rails blog}
  gem.homepage      = "http://www.github.com/avitus/bloggity"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "bloggity"
  gem.require_paths = ["lib"]
  gem.version       = Bloggity::VERSION
end
