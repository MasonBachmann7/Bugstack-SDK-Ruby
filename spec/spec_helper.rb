# frozen_string_literal: true

require "bugstack"
require "webmock/rspec"

WebMock.disable_net_connect!

RSpec.configure do |config|
  config.before(:each) do
    Bugstack.shutdown
  end

  config.after(:each) do
    Bugstack.shutdown
  end
end
