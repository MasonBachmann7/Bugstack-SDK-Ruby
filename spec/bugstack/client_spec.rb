# frozen_string_literal: true

require "spec_helper"

def make_exception(msg = "test error", klass = RuntimeError)
  raise klass, msg
rescue => e
  e
end

RSpec.describe Bugstack::Client do
  let(:config) do
    Bugstack::Configuration.new.tap do |c|
      c.api_key = "bs_test_key"
      c.dry_run = true
    end
  end

  subject(:client) { described_class.new(config) }

  after { client.shutdown }

  describe "#capture_exception" do
    it "returns true on success" do
      exc = make_exception("test error")
      expect(client.capture_exception(exc)).to be true
    end

    it "returns false when disabled" do
      config.enabled = false
      c = described_class.new(config)
      exc = make_exception("disabled")
      expect(c.capture_exception(exc)).to be false
    end

    it "accepts request context" do
      exc = make_exception("request test")
      result = client.capture_exception(exc, request: { route: "/api", method: "GET" })
      expect(result).to be true
    end

    it "accepts metadata" do
      exc = make_exception("meta test")
      result = client.capture_exception(exc, metadata: { "user_id" => "42" })
      expect(result).to be true
    end

    it "deduplicates same error" do
      exc = make_exception("dedup test")
      expect(client.capture_exception(exc)).to be true
      expect(client.capture_exception(exc)).to be false
    end

    it "allows different errors" do
      exc1 = make_exception("error one", RuntimeError)
      exc2 = make_exception("error two", ArgumentError)
      expect(client.capture_exception(exc1)).to be true
      expect(client.capture_exception(exc2)).to be true
    end
  end

  describe "ignored_errors" do
    it "ignores by type" do
      config.ignored_errors = [RuntimeError]
      c = described_class.new(config)
      exc = make_exception("ignored", RuntimeError)
      expect(c.capture_exception(exc)).to be false
    end

    it "ignores by message" do
      config.ignored_errors = ["expected error"]
      c = described_class.new(config)
      exc = make_exception("expected error")
      expect(c.capture_exception(exc)).to be false
    end

    it "passes non-ignored errors" do
      config.ignored_errors = [ArgumentError]
      c = described_class.new(config)
      exc = make_exception("not ignored", RuntimeError)
      expect(c.capture_exception(exc)).to be true
    end

    it "ignores subclasses" do
      config.ignored_errors = [StandardError]
      c = described_class.new(config)
      exc = make_exception("subclass", RuntimeError)
      expect(c.capture_exception(exc)).to be false
    end
  end

  describe "before_send" do
    it "drops event when returning nil" do
      config.before_send = ->(_event) { nil }
      c = described_class.new(config)
      exc = make_exception("dropped")
      expect(c.capture_exception(exc)).to be false
    end

    it "modifies event" do
      config.before_send = ->(event) {
        event.metadata["tag"] = "modified"
        event
      }
      c = described_class.new(config)
      exc = make_exception("modified")
      expect(c.capture_exception(exc)).to be true
    end

    it "passes event through spy" do
      captured = nil
      config.before_send = ->(event) {
        captured = event
        event
      }
      c = described_class.new(config)
      exc = make_exception("spy test")
      c.capture_exception(exc)
      expect(captured).not_to be_nil
      expect(captured.message).to eq("spy test")
    end
  end

  describe "never crashes" do
    it "handles internal errors gracefully" do
      config.before_send = ->(_event) { raise "hook exploded" }
      c = described_class.new(config)
      exc = make_exception("crash test")
      expect(c.capture_exception(exc)).to be false
    end
  end

  describe "dry_run" do
    it "prints to stdout" do
      exc = make_exception("dry run test")
      expect { client.capture_exception(exc) }.to output(/BugStack DryRun/).to_stdout
    end

    it "does not create transport" do
      expect(client.instance_variable_get(:@transport)).to be_nil
    end
  end

  describe "#shutdown" do
    it "is safe to call multiple times" do
      client.shutdown
      client.shutdown
    end
  end
end
