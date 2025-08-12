# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

# Suppress circular require warnings for Rails 7 compatibility
$VERBOSE = nil

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

# Add mocha for mocking/stubbing
begin
  require 'mocha/minitest'
rescue LoadError
  # Fall back to manual mocking if mocha isn't available
  puts "Warning: mocha gem not available, using manual mocking"
end

# Stub breadcrumb functionality after loading Rails
class ActionController::Base
  def self.add_breadcrumb(*args)
    # Stub method - do nothing in tests
  end
end

# Re-enable verbose mode after loading
$VERBOSE = true

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load fixtures from the engine
ActiveSupport::TestCase.fixture_paths = [File.expand_path("../fixtures", __FILE__)]

