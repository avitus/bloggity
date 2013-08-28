require 'thinking_sphinx'

module Bloggity
  class Engine < Rails::Engine

    isolate_namespace Bloggity

    config.to_prepare do

      Dir.glob(Rails.root + "app/decorators/**/*_decorator*.rb").each do |c|
        require_dependency(c)
      end

      # add bloggity helpers to main application
      ::ApplicationController.send :helper, Bloggity::Engine.helpers

      # Add Bloggity model directory when engine loads
      ThinkingSphinx::Configuration.instance.model_directories << "#{Rails.root}/app/models/"

    end

  end
end
