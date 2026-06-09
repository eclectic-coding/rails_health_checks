# frozen_string_literal: true

require "rails_helper"

RSpec.describe RailsHealthChecks::Checks::GoodJobCheck do
  context "when GoodJob is not installed" do
    it "raises LoadError on initialization" do
      hide_const("GoodJob")
      expect { described_class.new }.to raise_error(LoadError, /GoodJob is not installed/)
    end
  end

  context "when GoodJob is available" do
    let(:job_relation) { instance_double("GoodJob::Job::ActiveRecord_Relation") }

    before do
      stub_const("GoodJob", Module.new)
      stub_const("GoodJob::Job", Class.new do
        def self.where(*); end
      end)
      allow(GoodJob::Job).to receive(:where).and_return(job_relation)
      allow(job_relation).to receive(:where).and_return(job_relation)
      allow(job_relation).to receive(:minimum).and_return(nil)
    end

    subject(:check) { described_class.new }

    describe "#call" do
      context "when there are no pending jobs" do
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
        before { allow(GoodJob::Job).to receive(:where).and_raise(StandardError, "DB unavailable") }

        it "sets status to critical" do
          check.call
          expect(check.status).to eq("critical")
        end

        it "records the error message" do
          check.call
          expect(check.message).to eq("DB unavailable")
        end
      end

      context "with latency threshold" do
        let(:old_job_time) { Time.current - 120 }

        before { allow(job_relation).to receive(:minimum).and_return(old_job_time) }

        context "when latency is within threshold" do
          subject(:check) { described_class.new(latency: 300) }

          it "sets status to ok" do
            check.call
            expect(check.status).to eq("ok")
          end
        end

        context "when latency exceeds threshold" do
          subject(:check) { described_class.new(latency: 60) }

          it "sets status to degraded" do
            check.call
            expect(check.status).to eq("degraded")
          end

          it "includes age and threshold in message" do
            check.call
            expect(check.message).to match(/queue latency \d+s exceeds threshold 60s/)
          end
        end
      end
    end
  end
end
