# frozen_string_literal: true

require "spec_helper"

def make_exception(msg = "test error", klass = RuntimeError)
  raise klass, msg
rescue => e
  e
end

RSpec.describe Bugstack do
  describe ".init" do
    it "returns a client" do
      client = Bugstack.init(api_key: "bs_test_key", dry_run: true)
      expect(client).to be_a(Bugstack::Client)
    end

    it "sets the global client" do
      Bugstack.init(api_key: "bs_test_key", dry_run: true)
      expect(Bugstack.client).not_to be_nil
    end

    it "accepts block configuration" do
      Bugstack.init do |config|
        config.api_key = "bs_test_key"
        config.dry_run = true
        config.environment = "staging"
      end

      expect(Bugstack.client.config.environment).to eq("staging")
    end

    it "shuts down previous client on reinit" do
      c1 = Bugstack.init(api_key: "key_1", dry_run: true)
      c2 = Bugstack.init(api_key: "key_2", dry_run: true)
      expect(c1).not_to eq(c2)
    end
  end

  describe ".capture_exception" do
    it "captures when initialized" do
      Bugstack.init(api_key: "bs_test_key", dry_run: true)
      exc = make_exception("capture test")
      expect { Bugstack.capture_exception(exc) }.to output(/BugStack DryRun/).to_stdout
    end

    it "warns when not initialized" do
      expect { Bugstack.capture_exception(RuntimeError.new("no init")) }
        .to output(/Not initialized/).to_stderr
    end
  end

  describe ".client" do
    it "is nil before init" do
      expect(Bugstack.client).to be_nil
    end
  end

  describe ".shutdown" do
    it "is safe to call without init" do
      Bugstack.shutdown
    end

    it "clears the client" do
      Bugstack.init(api_key: "bs_test_key", dry_run: true)
      Bugstack.shutdown
      expect(Bugstack.client).to be_nil
    end
  end

  describe "VERSION" do
    it "is defined" do
      expect(Bugstack::VERSION).to eq("1.0.0")
    end
  end
end
