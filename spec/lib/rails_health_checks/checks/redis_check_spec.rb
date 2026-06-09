# frozen_string_literal: true

require "rails_helper"

RSpec.describe RailsHealthChecks::Checks::RedisCheck do
  context "when Redis is not installed" do
    it "raises LoadError on initialization" do
      hide_const("Redis")
      expect { described_class.new }.to raise_error(LoadError, /Redis is not installed/)
    end
  end

  context "when Redis is available" do
    let(:redis_client) { double("Redis client", ping: "PONG", close: nil) }

    before do
      stub_const("Redis", Class.new do
        def initialize(**); end
      end)
      allow(Redis).to receive(:new).and_return(redis_client)
    end

    subject(:check) { described_class.new }

    describe "#call" do
      context "when Redis is reachable" do
        it "sets status to ok" do
          check.call
          expect(check.status).to eq("ok")
        end

        it "records latency in milliseconds" do
          check.call
          expect(check.latency_ms).to be_a(Integer)
          expect(check.latency_ms).to be >= 0
        end

        it "closes the connection after pinging" do
          check.call
          expect(redis_client).to have_received(:close)
        end
      end

      context "when Redis is unreachable" do
        before { allow(redis_client).to receive(:ping).and_raise(StandardError, "connection refused") }

        it "sets status to critical" do
          check.call
          expect(check.status).to eq("critical")
        end

        it "records the error message" do
          check.call
          expect(check.message).to eq("connection refused")
        end
      end

      context "with a custom URL" do
        subject(:check) { described_class.new(url: "redis://custom-host:6380/1") }

        it "connects using the provided URL" do
          check.call
          expect(Redis).to have_received(:new).with(url: "redis://custom-host:6380/1")
        end
      end

      context "without a custom URL" do
        it "falls back to REDIS_URL env var or localhost default" do
          check.call
          expect(Redis).to have_received(:new).with(url: anything)
        end
      end
    end
  end
end
