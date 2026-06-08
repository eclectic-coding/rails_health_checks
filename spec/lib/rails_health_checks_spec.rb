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
  end
end
