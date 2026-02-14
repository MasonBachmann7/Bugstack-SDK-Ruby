# frozen_string_literal: true

require "spec_helper"

RSpec.describe Bugstack::Fingerprint do
  describe ".generate" do
    it "produces a 16-char hex string" do
      fp = described_class.generate("RuntimeError", "app.rb", "handler")
      expect(fp).to be_a(String)
      expect(fp.length).to eq(16)
      expect(fp).to match(/\A[0-9a-f]{16}\z/)
    end

    it "is stable for same inputs" do
      a = described_class.generate("RuntimeError", "app.rb", "handler", 42)
      b = described_class.generate("RuntimeError", "app.rb", "handler", 42)
      expect(a).to eq(b)
    end

    it "differs for different inputs" do
      a = described_class.generate("RuntimeError", "app.rb", "handler", 42)
      b = described_class.generate("TypeError", "app.rb", "handler", 42)
      expect(a).not_to eq(b)
    end

    it "includes line number when provided" do
      a = described_class.generate("RuntimeError", "app.rb", "handler")
      b = described_class.generate("RuntimeError", "app.rb", "handler", 10)
      expect(a).not_to eq(b)
    end
  end

  describe ".extract_location" do
    it "extracts from backtrace" do
      begin
        raise RuntimeError, "test"
      rescue => e
        exc_type, file, function, line = described_class.extract_location(e)
        expect(exc_type).to eq("RuntimeError")
        expect(file).to include("fingerprint_spec.rb")
        expect(line).to be_a(Integer)
        expect(line).to be > 0
      end
    end

    it "handles nil backtrace" do
      exc = RuntimeError.new("no bt")
      exc_type, file, function, line = described_class.extract_location(exc)
      expect(exc_type).to eq("RuntimeError")
      expect(file).to eq("")
      expect(line).to be_nil
    end
  end

  describe ".format_backtrace" do
    it "includes exception message" do
      begin
        raise RuntimeError, "format test"
      rescue => e
        result = described_class.format_backtrace(e)
        expect(result).to include("format test")
        expect(result).to include("RuntimeError")
      end
    end

    it "handles nil backtrace" do
      exc = RuntimeError.new("no bt")
      result = described_class.format_backtrace(exc)
      expect(result).to include("RuntimeError")
      expect(result).to include("no bt")
    end
  end
end

RSpec.describe Bugstack::Deduplicator do
  subject(:dedup) { described_class.new(window: 60.0) }

  it "allows first occurrence" do
    expect(dedup.should_send?("fp_abc")).to be true
  end

  it "blocks duplicate within window" do
    dedup.should_send?("fp_abc")
    expect(dedup.should_send?("fp_abc")).to be false
  end

  it "allows different fingerprints" do
    expect(dedup.should_send?("fp_1")).to be true
    expect(dedup.should_send?("fp_2")).to be true
  end

  it "allows after window expires" do
    dedup_short = described_class.new(window: 0.01)
    dedup_short.should_send?("fp_abc")
    sleep(0.02)
    expect(dedup_short.should_send?("fp_abc")).to be true
  end

  it "clears all entries" do
    dedup.should_send?("fp_abc")
    dedup.clear
    expect(dedup.should_send?("fp_abc")).to be true
  end
end
