# frozen_string_literal: true

require "rails_helper"

RSpec.describe RailsHealthChecks::Checks::CacheCheck do
  subject(:check) { described_class.new }

  describe "#call" do
    context "when the cache is available" do
      it "sets status to ok" do
        check.call
        expect(check.status).to eq("ok")
      end

      it "records latency in milliseconds" do
        check.call
        expect(check.latency_ms).to be_a(Integer)
        expect(check.latency_ms).to be >= 0
      end
    end

    context "when the cache write raises an error" do
      before { allow(Rails.cache).to receive(:write).and_raise(StandardError, "cache unavailable") }

      it "sets status to critical" do
        check.call
        expect(check.status).to eq("critical")
      end

      it "records the error message" do
        check.call
        expect(check.message).to eq("cache unavailable")
      end
    end

    context "when the cache read returns an unexpected value" do
      before do
        allow(Rails.cache).to receive(:write)
        allow(Rails.cache).to receive(:read).and_return(nil)
      end

      it "sets status to critical" do
        check.call
        expect(check.status).to eq("critical")
      end

      it "records an unexpected value message" do
        check.call
        expect(check.message).to include("unexpected value")
      end
    end
  end
end
