# frozen_string_literal: true

require "spec_helper"
require "bugstack/integrations/rails"

RSpec.describe Bugstack::Integrations::RackMiddleware do
  let(:app) { ->(env) { [200, {}, ["OK"]] } }
  let(:middleware) { described_class.new(app) }

  before do
    Bugstack.init(api_key: "bs_test_key", dry_run: true)
  end

  it "passes through normal requests" do
    env = { "PATH_INFO" => "/", "REQUEST_METHOD" => "GET" }
    status, _, body = middleware.call(env)
    expect(status).to eq(200)
    expect(body).to eq(["OK"])
  end

  it "captures and re-raises exceptions" do
    failing_app = ->(_env) { raise RuntimeError, "rack test error" }
    mw = described_class.new(failing_app)

    env = { "PATH_INFO" => "/fail", "REQUEST_METHOD" => "POST" }

    expect {
      mw.call(env)
    }.to raise_error(RuntimeError, "rack test error")
  end

  it "sends error in dry run mode" do
    failing_app = ->(_env) { raise RuntimeError, "captured error" }
    mw = described_class.new(failing_app)

    env = { "PATH_INFO" => "/fail", "REQUEST_METHOD" => "GET" }

    output = ""
    expect {
      begin
        mw.call(env)
      rescue RuntimeError
        # expected
      end
    }.to output(/BugStack DryRun/).to_stdout
  end
end
