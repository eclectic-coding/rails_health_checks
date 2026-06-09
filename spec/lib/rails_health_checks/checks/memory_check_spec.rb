# frozen_string_literal: true

require "rails_helper"
require "open3"

RSpec.describe RailsHealthChecks::Checks::MemoryCheck do
  def ps_output(rss_kb)
    "#{rss_kb}\n"
  end

  let(:rss_kb) { 102_400 }  # 100 MB

  before do
    allow(Open3).to receive(:capture3).with("ps", "-o", "rss=", "-p", Process.pid.to_s)
      .and_return([ps_output(rss_kb), "", instance_double(Process::Status, success?: true, exitstatus: 0)])
  end

  describe "#call" do
    context "when ps succeeds" do
      subject(:check) { described_class.new }

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

    context "when ps fails" do
      before do
        allow(Open3).to receive(:capture3).with("ps", "-o", "rss=", "-p", Process.pid.to_s)
          .and_return(["", "", instance_double(Process::Status, success?: false, exitstatus: 1)])
      end

      subject(:check) { described_class.new }

      it "sets status to critical" do
        check.call
        expect(check.status).to eq("critical")
      end

      it "records the error message" do
        check.call
        expect(check.message).to match(/ps command failed/)
      end
    end

    context "with a threshold" do
      context "when RSS is below threshold" do
        subject(:check) { described_class.new(threshold: 512 * 1024 * 1024) }  # 512 MB

        it "sets status to ok" do
          check.call
          expect(check.status).to eq("ok")
        end
      end

      context "when RSS exceeds threshold" do
        let(:rss_kb) { 614_400 }  # 600 MB
        subject(:check) { described_class.new(threshold: 512 * 1024 * 1024) }  # 512 MB

        it "sets status to degraded" do
          check.call
          expect(check.status).to eq("degraded")
        end

        it "includes RSS and threshold in message" do
          check.call
          rss = rss_kb * 1024
          expect(check.message).to eq("process RSS #{rss} bytes exceeds threshold #{512 * 1024 * 1024} bytes")
        end
      end
    end
  end
end
