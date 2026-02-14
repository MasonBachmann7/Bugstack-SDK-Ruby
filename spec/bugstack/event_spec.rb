# frozen_string_literal: true

require "spec_helper"

RSpec.describe Bugstack::Event do
  let(:config) do
    Bugstack::Configuration.new.tap { |c| c.api_key = "bs_test_key" }
  end

  describe "#to_payload" do
    it "serializes minimal event" do
      event = described_class.new(
        message: "something broke",
        stack_trace: "Traceback ...",
        file: "app.rb",
        function: "handler",
        fingerprint: "abc123",
        exception_type: "RuntimeError",
        timestamp: "2026-01-01T00:00:00Z"
      )

      payload = event.to_payload(config)

      expect(payload["apiKey"]).to eq("bs_test_key")
      expect(payload["error"]["message"]).to eq("something broke")
      expect(payload["error"]["stackTrace"]).to eq("Traceback ...")
      expect(payload["error"]["file"]).to eq("app.rb")
      expect(payload["error"]["function"]).to eq("handler")
      expect(payload["error"]["fingerprint"]).to eq("abc123")
      expect(payload["environment"]["language"]).to eq("ruby")
      expect(payload["environment"]["sdkVersion"]).to eq(Bugstack::VERSION)
      expect(payload).not_to have_key("request")
    end

    it "includes request context" do
      event = described_class.new(
        message: "err",
        request: { route: "/api/users", method: "GET" }
      )

      payload = event.to_payload(config)
      expect(payload["request"]["route"]).to eq("/api/users")
      expect(payload["request"]["method"]).to eq("GET")
    end

    it "includes project_id" do
      config.project_id = "proj_123"
      event = described_class.new(message: "err")
      payload = event.to_payload(config)
      expect(payload["projectId"]).to eq("proj_123")
    end

    it "includes metadata" do
      event = described_class.new(message: "err", metadata: { "user" => "42" })
      payload = event.to_payload(config)
      expect(payload["metadata"]["user"]).to eq("42")
    end

    it "adds autoFix flag" do
      config.auto_fix = true
      event = described_class.new(message: "err")
      payload = event.to_payload(config)
      expect(payload["metadata"]["autoFix"]).to be true
    end
  end
end
