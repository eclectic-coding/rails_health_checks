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

    it "builds an smtp check" do
      result = described_class.build([:smtp])
      expect(result[:smtp]).to be_a(RailsHealthChecks::Checks::SmtpCheck)
    end

    it "builds a redis check when Redis is available" do
      stub_const("Redis", Class.new do
        def self.new(**); end
      end)
      result = described_class.build([:redis])
      expect(result[:redis]).to be_a(RailsHealthChecks::Checks::RedisCheck)
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

    it "builds an http check" do
      RailsHealthChecks.configuration.http_url = "http://example.com"
      result = described_class.build([:http])
      expect(result[:http]).to be_a(RailsHealthChecks::Checks::HttpCheck)
    end

    it "builds a disk check" do
      result = described_class.build([:disk])
      expect(result[:disk]).to be_a(RailsHealthChecks::Checks::DiskCheck)
    end

    context "with a custom registered check" do
      let(:custom_check) do
        Class.new(RailsHealthChecks::Check) do
          def call = pass("custom ok")
        end.new
      end

      before do
        RailsHealthChecks.configuration.register(:my_service, custom_check)
      end

      after do
        RailsHealthChecks.instance_variable_set(:@configuration, nil)
      end

      it "builds the custom check by name" do
        result = described_class.build([:my_service])
        expect(result[:my_service]).to be_a(RailsHealthChecks::Check)
      end

      it "returns a dup so state does not leak between builds" do
        result1 = described_class.build([:my_service])
        result2 = described_class.build([:my_service])
        expect(result1[:my_service]).not_to be(result2[:my_service])
      end

      it "runs the custom check successfully" do
        result = described_class.build([:my_service])
        described_class.run(result, timeout: 5)
        expect(result[:my_service].status).to eq("ok")
        expect(result[:my_service].message).to eq("custom ok")
      end
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

    context "ActiveSupport::Notifications" do
      it "publishes health_check.rails_health_checks with status and check results" do
        events = []
        subscription = ActiveSupport::Notifications.subscribe("health_check.rails_health_checks") do |*args|
          events << ActiveSupport::Notifications::Event.new(*args)
        end

        described_class.run(checks, timeout: 5)

        expect(events.length).to eq(1)
        payload = events.first.payload
        expect(payload[:status]).to eq("ok")
        expect(payload[:checks]).to have_key(:database)
        expect(payload[:checks][:database][:status]).to eq("ok")
      ensure
        ActiveSupport::Notifications.unsubscribe(subscription)
      end

      it "includes duration information for subscribers" do
        events = []
        subscription = ActiveSupport::Notifications.subscribe("health_check.rails_health_checks") do |*args|
          events << ActiveSupport::Notifications::Event.new(*args)
        end

        described_class.run(checks, timeout: 5)

        expect(events.first.duration).to be > 0
      ensure
        ActiveSupport::Notifications.unsubscribe(subscription)
      end
    end

    context "when a check has a per-check timeout" do
      let(:slow_check) do
        Class.new(RailsHealthChecks::Check) do
          def call = (sleep 10) && pass("done")
        end.new.tap { |c| c.timeout = 1 }
      end

      it "uses the check's own timeout instead of the global one" do
        results = described_class.run({ slow: slow_check }, timeout: 30)
        expect(results[:slow].status).to eq("critical")
        expect(results[:slow].message).to eq("timed out")
      end
    end

    context "with multiple checks running in parallel" do
      let(:slow_check_class) do
        Class.new(RailsHealthChecks::Check) do
          def call
            sleep 0.1
            pass "done"
          end
        end
      end

      it "completes faster than sequential execution would allow" do
        checks = 4.times.each_with_object({}) do |i, h|
          h[:"check_#{i}"] = slow_check_class.new
        end

        t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        described_class.run(checks, timeout: 5)
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0

        # 4 checks × 0.1s each = 0.4s sequential; parallel should finish well under that
        expect(elapsed).to be < 0.35
        checks.each_value { |c| expect(c.status).to eq("ok") }
      end
    end
  end
end
