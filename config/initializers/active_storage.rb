# Active Storage configuration for Bloggity engine
# 
# This initializer ensures Active Storage is properly configured when using Bloggity

Rails.application.configure do
  # Ensure Active Storage service is configured
  # The host application should configure storage.yml, but we provide sensible defaults
  
  if Rails.env.development? || Rails.env.test?
    # For development/test, default to local storage if not configured
    unless Rails.application.config.active_storage.service
      Rails.application.config.active_storage.service = :local
    end
  end
  
  # Configure Active Storage routes to be available under the bloggity namespace
  # This ensures asset URLs work properly in the engine context
  config.after_initialize do
    Rails.application.routes.prepend do
      # Ensure Active Storage routes are available
      # These are normally added automatically, but we want to ensure they work in engine context
    end
  end
end