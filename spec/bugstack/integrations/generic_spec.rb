# frozen_string_literal: true

require "spec_helper"
require "bugstack/integrations/generic"

RSpec.describe Bugstack::Integrations::Generic do
  after { described_class.reset! }

  it "tracks installation state" do
    expect(described_class.installed?).to be false
    described_class.install!
    expect(described_class.installed?).to be true
  end

  it "is idempotent" do
    described_class.install!
    described_class.install!
    expect(described_class.installed?).to be true
  end

  it "can be reset" do
    described_class.install!
    described_class.reset!
    expect(described_class.installed?).to be false
  end
end
