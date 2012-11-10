module Bloggity
  class Engine < ::Rails::Engine

    isolate_namespace Bloggity

    config.to_prepare do

      Dir.glob(Rails.root + "app/decorators/**/*_decorator*.rb").each do |c|
        require_dependency(c)
      end

      require_dependency 'bloggity/bloggity_application'

      # add bloggity helpers to main application
      ::ApplicationController.send :helper, Bloggity::Engine.helpers

    end


  end
end
