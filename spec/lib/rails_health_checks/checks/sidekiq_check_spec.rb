# frozen_string_literal: true

require "rails_helper"

RSpec.describe RailsHealthChecks::Checks::SidekiqCheck do
  context "when Sidekiq is not installed" do
    it "raises LoadError on initialization" do
      hide_const("Sidekiq")
      expect { described_class.new }.to raise_error(LoadError, /Sidekiq is not installed/)
    end
  end

  context "when Sidekiq is available" do
    let(:redis_conn) { double("conn", ping: "PONG") }

    before do
      stub_const("Sidekiq", Module.new { def self.redis; end })
      stub_const("Sidekiq::Queue", Class.new { def self.all; end })
      allow(Sidekiq).to receive(:redis).and_yield(redis_conn)
      allow(Sidekiq::Queue).to receive(:all).and_return([])
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
        before { allow(Sidekiq).to receive(:redis).and_raise(StandardError, "connection refused") }

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
        let(:queues) { [double("q1", size: 600), double("q2", size: 500)] }

        before { allow(Sidekiq::Queue).to receive(:all).and_return(queues) }

        context "when depth is within threshold" do
          subject(:check) { described_class.new(queue_size: 2000) }

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
            expect(check.message).to eq("queue depth 1100 exceeds threshold 500")
          end
        end
      end
    end
  end
end
