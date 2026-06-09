# frozen_string_literal: true

require "rails_helper"

RSpec.describe RailsHealthChecks::Configuration do
  subject(:config) { described_class.new }

  describe "#validate!" do
    it "does not raise for the default configuration" do
      expect { config.validate! }.not_to raise_error
    end

    it "does not raise when all checks are known built-ins" do
      config.checks = [:database, :cache, :disk]
      expect { config.validate! }.not_to raise_error
    end

    it "raises ConfigurationError for an unknown check name" do
      config.checks = [:database, :nonexistent]
      expect { config.validate! }.to raise_error(RailsHealthChecks::ConfigurationError, /nonexistent/)
    end

    it "raises ConfigurationError when :http is included but http_url is not set" do
      config.checks = [:http]
      config.http_url = nil
      expect { config.validate! }.to raise_error(RailsHealthChecks::ConfigurationError, /http_url/)
    end

    it "does not raise when :http is included and http_url is set" do
      config.checks = [:http]
      config.http_url = "http://example.com/status"
      expect { config.validate! }.not_to raise_error
    end

    it "raises ConfigurationError when a group references an unknown check" do
      config.group(:infra, [:database, :missing_check])
      expect { config.validate! }.to raise_error(RailsHealthChecks::ConfigurationError, /missing_check/)
    end

    it "does not raise when a group references a custom registered check" do
      custom = Class.new(RailsHealthChecks::Check) { def call = pass("ok") }.new
      config.register(:my_svc, custom)
      config.group(:app, [:database, :my_svc])
      expect { config.validate! }.not_to raise_error
    end
  end

  describe "defaults" do
    it "defaults cache_duration to nil (disabled)" do
      expect(config.cache_duration).to be_nil
    end

    it "defaults http_headers to an empty hash" do
      expect(config.http_headers).to eq({})
    end
  end
end
