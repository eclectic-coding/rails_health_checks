# frozen_string_literal: true

require "rails_helper"
require "generators/rails_health_checks/initializer_generator"

RSpec.describe RailsHealthChecks::Generators::InitializerGenerator do
  let(:destination)       { File.expand_path("../../../tmp/generator", __dir__) }
  let(:initializer_path)  { File.join(destination, "config/initializers/rails_health_checks.rb") }
  let(:initializer_content) { File.read(initializer_path) }

  around do |example|
    FileUtils.mkdir_p(destination)
    example.run
    FileUtils.rm_rf(destination)
  end

  before do
    described_class.new([], {}, destination_root: destination).invoke_all
  end

  it "creates config/initializers/rails_health_checks.rb" do
    expect(File).to exist(initializer_path)
  end

  it "includes the frozen_string_literal magic comment" do
    expect(initializer_content).to start_with("# frozen_string_literal: true")
  end

  it "sets config.checks to [:database] as the default" do
    expect(initializer_content).to include("config.checks = [:database]")
  end

  it "lists all built-in check names" do
    %w[database cache sidekiq solid_queue good_job resque disk memory http].each do |name|
      expect(initializer_content).to include(name)
    end
  end

  it "includes timeout configuration" do
    expect(initializer_content).to include("config.timeout = 5")
  end

  it "includes cache_duration as a commented option" do
    expect(initializer_content).to include("config.cache_duration")
  end

  it "includes all authentication strategies" do
    expect(initializer_content).to include("config.token")
    expect(initializer_content).to include("config.allowed_ips")
    expect(initializer_content).to include("config.authenticate")
  end

  it "includes per-environment toggling example" do
    expect(initializer_content).to include("config.disable")
  end

  it "includes group configuration example" do
    expect(initializer_content).to include("config.group")
  end

  it "includes http check options" do
    expect(initializer_content).to include("config.http_url")
    expect(initializer_content).to include("config.http_expected_status")
    expect(initializer_content).to include("config.http_headers")
  end

  it "includes disk check options" do
    expect(initializer_content).to include("config.disk_path")
    expect(initializer_content).to include("config.disk_warn_threshold")
    expect(initializer_content).to include("config.disk_critical_threshold")
  end

  it "includes memory check option" do
    expect(initializer_content).to include("config.memory_threshold")
  end

  it "includes queue depth options for all job backends" do
    expect(initializer_content).to include("config.sidekiq_queue_size")
    expect(initializer_content).to include("config.solid_queue_job_count")
    expect(initializer_content).to include("config.good_job_latency")
    expect(initializer_content).to include("config.resque_queue_size")
  end

  it "includes custom check registration example" do
    expect(initializer_content).to include("config.register")
  end
end
