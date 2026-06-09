# frozen_string_literal: true

require "rails_helper"
require "open3"

RSpec.describe RailsHealthChecks::Checks::DiskCheck do
  # df -Pk output: Filesystem  1024-blocks  Used  Available  Capacity%  Mounted-on
  def df_output(available_kb)
    "Filesystem     1024-blocks      Used Available Capacity Mounted on\n" \
      "/dev/disk1     244140625  87890625 #{available_kb}      37% /\n"
  end

  describe "#call" do
    context "when df succeeds" do
      let(:available_kb) { 5_000_000 }  # ~4.8 GB free
      let(:free_bytes) { available_kb * 1024 }

      before do
        allow(Open3).to receive(:capture3).with("df", "-Pk", "/")
          .and_return([df_output(available_kb), "", instance_double(Process::Status, success?: true, exitstatus: 0)])
      end

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

    context "when df fails" do
      before do
        allow(Open3).to receive(:capture3).with("df", "-Pk", "/")
          .and_return(["", "", instance_double(Process::Status, success?: false, exitstatus: 1)])
      end

      subject(:check) { described_class.new }

      it "sets status to critical" do
        check.call
        expect(check.status).to eq("critical")
      end

      it "records the error message" do
        check.call
        expect(check.message).to match(/df command failed/)
      end
    end

    context "with warn threshold" do
      subject(:check) { described_class.new(warn_threshold: 10_737_418_240) }  # 10 GB

      context "when free space is above warn threshold" do
        let(:available_kb) { 20_000_000 }  # ~19 GB free

        before do
          allow(Open3).to receive(:capture3).with("df", "-Pk", "/")
            .and_return([df_output(available_kb), "", instance_double(Process::Status, success?: true, exitstatus: 0)])
        end

        it "sets status to ok" do
          check.call
          expect(check.status).to eq("ok")
        end
      end

      context "when free space is below warn threshold" do
        let(:available_kb) { 5_000_000 }  # ~4.8 GB free, below 10 GB warn

        before do
          allow(Open3).to receive(:capture3).with("df", "-Pk", "/")
            .and_return([df_output(available_kb), "", instance_double(Process::Status, success?: true, exitstatus: 0)])
        end

        it "sets status to degraded" do
          check.call
          expect(check.status).to eq("degraded")
        end

        it "includes free space and threshold in message" do
          check.call
          free = available_kb * 1024
          expect(check.message).to eq("free disk space #{free} bytes below warn threshold 10737418240 bytes")
        end
      end
    end

    context "with critical threshold" do
      subject(:check) { described_class.new(critical_threshold: 2_147_483_648) }  # 2 GB

      context "when free space is above critical threshold" do
        let(:available_kb) { 5_000_000 }  # ~4.8 GB free

        before do
          allow(Open3).to receive(:capture3).with("df", "-Pk", "/")
            .and_return([df_output(available_kb), "", instance_double(Process::Status, success?: true, exitstatus: 0)])
        end

        it "sets status to ok" do
          check.call
          expect(check.status).to eq("ok")
        end
      end

      context "when free space is below critical threshold" do
        let(:available_kb) { 1_000_000 }  # ~976 MB free, below 2 GB critical

        before do
          allow(Open3).to receive(:capture3).with("df", "-Pk", "/")
            .and_return([df_output(available_kb), "", instance_double(Process::Status, success?: true, exitstatus: 0)])
        end

        it "sets status to critical" do
          check.call
          expect(check.status).to eq("critical")
        end

        it "includes free space and threshold in message" do
          check.call
          free = available_kb * 1024
          expect(check.message).to eq("free disk space #{free} bytes below critical threshold 2147483648 bytes")
        end
      end
    end

    context "with both warn and critical thresholds" do
      let(:available_kb) { 500_000 }  # ~488 MB free

      before do
        allow(Open3).to receive(:capture3).with("df", "-Pk", "/")
          .and_return([df_output(available_kb), "", instance_double(Process::Status, success?: true, exitstatus: 0)])
      end

      context "when free space is below critical threshold" do
        subject(:check) { described_class.new(warn_threshold: 2_147_483_648, critical_threshold: 1_073_741_824) }

        it "sets status to critical (not degraded)" do
          check.call
          expect(check.status).to eq("critical")
        end
      end
    end

    context "with a custom path" do
      subject(:check) { described_class.new(path: "/var") }

      before do
        allow(Open3).to receive(:capture3).with("df", "-Pk", "/var")
          .and_return([df_output(5_000_000), "", instance_double(Process::Status, success?: true, exitstatus: 0)])
      end

      it "passes the custom path to df" do
        check.call
        expect(Open3).to have_received(:capture3).with("df", "-Pk", "/var")
      end

      it "sets status to ok" do
        check.call
        expect(check.status).to eq("ok")
      end
    end
  end
end
