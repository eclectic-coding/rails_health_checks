# frozen_string_literal: true

require "rails_helper"

RSpec.describe RailsHealthChecks do
  describe ".configure" do
    after { described_class.instance_variable_set(:@configuration, nil) }

    it "yields the configuration object" do
      described_class.configure do |config|
        expect(config).to be_a(RailsHealthChecks::Configuration)
      end
    end

    it "allows setting configuration values" do
      described_class.configure { |c| c.timeout = 10 }
      expect(described_class.configuration.timeout).to eq(10)
    end

    describe "config.register" do
      let(:custom_check) do
        Class.new(RailsHealthChecks::Check) do
          def call = pass("custom ok")
        end.new
      end

      it "stores the check in custom_checks" do
        described_class.configure { |c| c.register(:my_check, custom_check) }
        expect(described_class.configuration.custom_checks[:my_check]).to eq(custom_check)
      end

      it "appends the name to config.checks" do
        described_class.configure { |c| c.register(:my_check, custom_check) }
        expect(described_class.configuration.checks).to include(:my_check)
      end

      it "does not duplicate the name in config.checks when called twice" do
        described_class.configure do |c|
          c.register(:my_check, custom_check)
          c.register(:my_check, custom_check)
        end
        expect(described_class.configuration.checks.count(:my_check)).to eq(1)
      end
    end
  end
end
