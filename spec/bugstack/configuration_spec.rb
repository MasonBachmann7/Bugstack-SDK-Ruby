# frozen_string_literal: true

require "spec_helper"

RSpec.describe Bugstack::Configuration do
  subject(:config) { described_class.new }

  it "has sensible defaults" do
    expect(config.api_key).to eq("")
    expect(config.endpoint).to eq("https://api.bugstack.dev/api/capture")
    expect(config.environment).to eq("production")
    expect(config.auto_fix).to be false
    expect(config.enabled).to be true
    expect(config.debug).to be false
    expect(config.dry_run).to be false
    expect(config.deduplication_window).to eq(300.0)
    expect(config.timeout).to eq(5.0)
    expect(config.max_retries).to eq(3)
    expect(config.ignored_errors).to eq([])
    expect(config.before_send).to be_nil
  end

  it "allows setting values" do
    config.api_key = "bs_test_key"
    config.endpoint = "https://custom.api.dev"
    config.environment = "staging"
    config.auto_fix = true

    expect(config.api_key).to eq("bs_test_key")
    expect(config.endpoint).to eq("https://custom.api.dev")
    expect(config.environment).to eq("staging")
    expect(config.auto_fix).to be true
  end
end
