# frozen_string_literal: true

require "spec_helper"

RSpec.describe Bugstack::Transport do
  describe "#enqueue and sending" do
    it "sends payload to endpoint" do
      stub = stub_request(:post, "https://api.test.dev/capture")
        .to_return(status: 200, body: '{"ok":true}')

      transport = described_class.new(
        endpoint: "https://api.test.dev/capture",
        api_key: "bs_test_key",
        timeout: 2.0,
        max_retries: 1
      )

      transport.enqueue({ "apiKey" => "bs_test_key", "error" => { "message" => "test" } })
      sleep(1)
      transport.shutdown

      expect(stub).to have_been_requested
    end

    it "sends correct headers" do
      stub = stub_request(:post, "https://api.test.dev/capture")
        .with(headers: {
          "Content-Type" => "application/json",
          "X-BugStack-API-Key" => "bs_test_key",
          "X-BugStack-SDK-Version" => Bugstack::VERSION
        })
        .to_return(status: 200)

      transport = described_class.new(
        endpoint: "https://api.test.dev/capture",
        api_key: "bs_test_key"
      )

      transport.enqueue({ "test" => true })
      sleep(1)
      transport.shutdown

      expect(stub).to have_been_requested
    end

    it "retries on failure" do
      call_count = 0
      stub = stub_request(:post, "https://api.test.dev/capture")
        .to_return do |_request|
          call_count += 1
          if call_count <= 1
            { status: 500, body: "error" }
          else
            { status: 200, body: '{"ok":true}' }
          end
        end

      transport = described_class.new(
        endpoint: "https://api.test.dev/capture",
        api_key: "bs_test_key",
        max_retries: 3
      )

      transport.enqueue({ "test" => true })
      sleep(5)
      transport.shutdown

      expect(call_count).to be >= 2
    end
  end

  describe "#shutdown" do
    it "is safe to call" do
      transport = described_class.new(
        endpoint: "https://api.test.dev/capture",
        api_key: "bs_test_key"
      )
      transport.shutdown
    end
  end
end
