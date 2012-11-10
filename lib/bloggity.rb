require "active_support/dependencies"

require "bloggity/engine"
require "bloggity/bloggity_application"

module Bloggity

	# ALV: Added
	# Our host application root path
    # We set this when the engine is initialized
	mattr_accessor :app_root

end
