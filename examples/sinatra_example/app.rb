# Sinatra example with BugStack error capture.
#
# Run: ruby app.rb

require "sinatra"
require "bugstack"
require "bugstack/integrations/sinatra"

Bugstack.init do |config|
  config.api_key = "bs_live_your_api_key_here"
  config.auto_fix = true
  config.debug = true
end

class MyApp < Sinatra::Base
  register Bugstack::Integrations::Sinatra

  get "/" do
    "Hello, World!"
  end

  get "/fail" do
    raise RuntimeError, "Something went wrong!"
  end
end
