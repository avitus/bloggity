# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

# Suppress circular require warnings for Rails 7 compatibility
$VERBOSE = nil

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

# Re-enable verbose mode after loading
$VERBOSE = true

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load fixtures from the engine
ActiveSupport::TestCase.fixture_paths = [File.expand_path("../fixtures", __FILE__)]
