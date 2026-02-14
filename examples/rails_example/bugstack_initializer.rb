# config/initializers/bugstack.rb
#
# Copy this file to your Rails app's config/initializers/ directory.

require "bugstack"

Bugstack.init do |config|
  config.api_key = Rails.application.credentials.bugstack_api_key
  config.environment = Rails.env
  config.auto_fix = true
end
