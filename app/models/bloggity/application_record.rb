module Bloggity
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
    
    # Rails 7+ requires belongs_to associations by default.
    # Bloggity models need optional associations (e.g., BlogPost without category)
    # so we disable this requirement for all Bloggity models.
    self.belongs_to_required_by_default = false
  end
end