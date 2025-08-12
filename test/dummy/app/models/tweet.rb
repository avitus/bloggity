# Stub model for testing - BlogPost references Tweet in tweet_public_publish callback
class Tweet < ActiveRecord::Base
  # This is a simple stub to prevent errors during testing
  def self.create(attributes = {})
    # Do nothing - just prevent the error
  end
end