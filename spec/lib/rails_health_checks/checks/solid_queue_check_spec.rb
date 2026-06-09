# frozen_string_literal: true

require "rails_helper"

RSpec.describe RailsHealthChecks::Checks::SolidQueueCheck do
  context "when SolidQueue is not installed" do
    it "raises LoadError on initialization" do
      hide_const("SolidQueue")
      expect { described_class.new }.to raise_error(LoadError, /SolidQueue is not installed/)
    end
  end

  context "when SolidQueue is available" do
    before do
      stub_const("SolidQueue", Module.new)
      stub_const("SolidQueue::ReadyExecution", Class.new { def self.count; end })
      allow(SolidQueue::ReadyExecution).to receive(:count).and_return(0)
    end

    subject(:check) { described_class.new }

    describe "#call" do
      context "when the database is reachable" do
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

      context "when the database raises an error" do
        before { allow(SolidQueue::ReadyExecution).to receive(:count).and_raise(StandardError, "DB unavailable") }

        it "sets status to critical" do
          check.call
          expect(check.status).to eq("critical")
        end

        it "records the error message" do
          check.call
          expect(check.message).to eq("DB unavailable")
        end
      end

      context "with job count threshold" do
        before { allow(SolidQueue::ReadyExecution).to receive(:count).and_return(150) }

        context "when pending count is within threshold" do
          subject(:check) { described_class.new(job_count: 200) }

          it "sets status to ok" do
            check.call
            expect(check.status).to eq("ok")
          end
        end

        context "when pending count exceeds threshold" do
          subject(:check) { described_class.new(job_count: 100) }

          it "sets status to degraded" do
            check.call
            expect(check.status).to eq("degraded")
          end

          it "includes count and threshold in message" do
            check.call
            expect(check.message).to eq("pending job count 150 exceeds threshold 100")
          end
        end
      end
    end
  end
end
