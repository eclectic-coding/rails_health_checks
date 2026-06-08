# frozen_string_literal: true

require "rails_helper"

RSpec.describe RailsHealthChecks::Check do
  subject(:check) { described_class.new }

  describe "#call" do
    it "raises NotImplementedError" do
      expect { check.call }.to raise_error(NotImplementedError, /must implement #call/)
    end
  end

  describe "#warn_with" do
    it "sets status to degraded and stores the message" do
      check.send(:warn_with, "elevated latency")
      expect(check.status).to eq("degraded")
      expect(check.message).to eq("elevated latency")
    end
  end
end
