# frozen_string_literal: true

require "rails_helper"

RSpec.describe RailsHealthChecks::Checks::ResqueCheck do
  context "when Resque is not installed" do
    it "raises LoadError on initialization" do
      hide_const("Resque")
      expect { described_class.new }.to raise_error(LoadError, /Resque is not installed/)
    end
  end

  context "when Resque is available" do
    let(:redis_conn) { double("conn", ping: "PONG") }

    before do
      stub_const("Resque", Module.new do
        def self.redis; end
        def self.queues; end
        def self.size(_queue); end
      end)
      allow(Resque).to receive(:redis).and_return(redis_conn)
      allow(Resque).to receive(:queues).and_return([])
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
      end

      context "when Redis is unreachable" do
        before { allow(Resque).to receive(:redis).and_raise(StandardError, "connection refused") }

        it "sets status to critical" do
          check.call
          expect(check.status).to eq("critical")
        end

        it "records the error message" do
          check.call
          expect(check.message).to eq("connection refused")
        end
      end

      context "with queue depth threshold" do
        before do
          allow(Resque).to receive(:queues).and_return(["default", "mailers"])
          allow(Resque).to receive(:size).with("default").and_return(400)
          allow(Resque).to receive(:size).with("mailers").and_return(200)
        end

        context "when depth is within threshold" do
          subject(:check) { described_class.new(queue_size: 1000) }

          it "sets status to ok" do
            check.call
            expect(check.status).to eq("ok")
          end
        end

        context "when depth exceeds threshold" do
          subject(:check) { described_class.new(queue_size: 500) }

          it "sets status to degraded" do
            check.call
            expect(check.status).to eq("degraded")
          end

          it "includes depth and threshold in message" do
            check.call
            expect(check.message).to eq("queue depth 600 exceeds threshold 500")
          end
        end
      end
    end
  end
end
