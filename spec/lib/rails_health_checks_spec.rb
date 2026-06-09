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

    describe "config.disable" do
      before { described_class.configure { |c| c.checks = [:database, :disk, :memory] } }

      context "when the current environment matches" do
        it "omits the check from config.checks" do
          described_class.configure { |c| c.disable :disk, in: :test }
          expect(described_class.configuration.checks).not_to include(:disk)
        end

        it "leaves other checks intact" do
          described_class.configure { |c| c.disable :disk, in: :test }
          expect(described_class.configuration.checks).to include(:database, :memory)
        end
      end

      context "when the current environment does not match" do
        it "keeps the check in config.checks" do
          described_class.configure { |c| c.disable :disk, in: :production }
          expect(described_class.configuration.checks).to include(:disk)
        end
      end

      context "with multiple environments" do
        it "disables the check when the current env is any of the listed envs" do
          described_class.configure { |c| c.disable :disk, in: [:test, :development] }
          expect(described_class.configuration.checks).not_to include(:disk)
        end
      end
    end

    describe "config.group" do
      it "stores check names under the group key" do
        described_class.configure { |c| c.group(:infra, [:database, :disk]) }
        expect(described_class.configuration.groups[:infra]).to eq([:database, :disk])
      end

      it "stores multiple groups independently" do
        described_class.configure do |c|
          c.group(:infra, [:database, :disk])
          c.group(:workers, [:sidekiq])
        end
        expect(described_class.configuration.groups.keys).to contain_exactly(:infra, :workers)
      end
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
