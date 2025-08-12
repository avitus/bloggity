module Bloggity
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
    
    # Disable Rails 5+ default that requires belongs_to associations
    # This allows Bloggity models to have optional associations
    if Rails::VERSION::MAJOR >= 5
      self.belongs_to_required_by_default = false
    end
  end
end