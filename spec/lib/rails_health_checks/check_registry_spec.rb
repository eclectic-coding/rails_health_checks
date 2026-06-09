# frozen_string_literal: true

require "rails_helper"

RSpec.describe RailsHealthChecks::CheckRegistry do
  describe ".build" do
    it "returns a hash of instantiated checks for known names" do
      result = described_class.build([:database])
      expect(result[:database]).to be_a(RailsHealthChecks::Checks::DatabaseCheck)
    end

    it "builds a cache check" do
      result = described_class.build([:cache])
      expect(result[:cache]).to be_a(RailsHealthChecks::Checks::CacheCheck)
    end

    it "raises ArgumentError for unknown check names" do
      expect { described_class.build([:unknown]) }
        .to raise_error(ArgumentError, /Unknown check: unknown/)
    end
  end

  describe ".run" do
    let(:check) { RailsHealthChecks::Checks::DatabaseCheck.new }
    let(:checks) { { database: check } }

    context "when a check times out" do
      before { allow(check).to receive(:call).and_raise(Timeout::Error) }

      it "sets status to critical with timed out message" do
        results = described_class.run(checks, timeout: 5)
        expect(results[:database].status).to eq("critical")
        expect(results[:database].message).to eq("timed out")
      end
    end

    context "when a check raises a StandardError" do
      before { allow(check).to receive(:call).and_raise(StandardError, "connection refused") }

      it "sets status to critical with the error message" do
        results = described_class.run(checks, timeout: 5)
        expect(results[:database].status).to eq("critical")
        expect(results[:database].message).to eq("connection refused")
      end
    end
  end
end
