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

    it "builds a resque check when Resque is available" do
      stub_const("Resque", Module.new do
        def self.redis; end
        def self.queues; end
        def self.size(_queue); end
      end)
      result = described_class.build([:resque])
      expect(result[:resque]).to be_a(RailsHealthChecks::Checks::ResqueCheck)
    end

    it "builds a good_job check when GoodJob is available" do
      stub_const("GoodJob", Module.new)
      stub_const("GoodJob::Job", Class.new { def self.where(*); end })
      result = described_class.build([:good_job])
      expect(result[:good_job]).to be_a(RailsHealthChecks::Checks::GoodJobCheck)
    end

    it "builds a solid_queue check when SolidQueue is available" do
      stub_const("SolidQueue", Module.new)
      stub_const("SolidQueue::ReadyExecution", Class.new { def self.count; end })
      result = described_class.build([:solid_queue])
      expect(result[:solid_queue]).to be_a(RailsHealthChecks::Checks::SolidQueueCheck)
    end

    it "builds a sidekiq check when Sidekiq is available" do
      stub_const("Sidekiq", Module.new { def self.redis; end })
      stub_const("Sidekiq::Queue", Class.new { def self.all; end })
      result = described_class.build([:sidekiq])
      expect(result[:sidekiq]).to be_a(RailsHealthChecks::Checks::SidekiqCheck)
    end

    it "builds a memory check" do
      result = described_class.build([:memory])
      expect(result[:memory]).to be_a(RailsHealthChecks::Checks::MemoryCheck)
    end

    it "builds a disk check" do
      result = described_class.build([:disk])
      expect(result[:disk]).to be_a(RailsHealthChecks::Checks::DiskCheck)
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
