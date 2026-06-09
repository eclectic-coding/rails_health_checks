# frozen_string_literal: true

require "rails_helper"

RSpec.describe RailsHealthChecks::PrometheusFormatter do
  def build_check(status, latency_ms: nil)
    check = RailsHealthChecks::Check.new
    check.instance_variable_set(:@status, status)
    check.instance_variable_set(:@latency_ms, latency_ms)
    check
  end

  let(:results) do
    {
      database: build_check("ok", latency_ms: 3),
      cache:    build_check("degraded", latency_ms: 12),
      worker:   build_check("critical")
    }
  end

  subject(:output) { described_class.new(results).to_text }

  it "includes the status HELP and TYPE headers" do
    expect(output).to include("# HELP rails_health_check_status")
    expect(output).to include("# TYPE rails_health_check_status gauge")
  end

  it "maps ok status to 0" do
    expect(output).to include('rails_health_check_status{check="database"} 0')
  end

  it "maps degraded status to 1" do
    expect(output).to include('rails_health_check_status{check="cache"} 1')
  end

  it "maps critical status to 2" do
    expect(output).to include('rails_health_check_status{check="worker"} 2')
  end

  it "includes the latency HELP and TYPE headers" do
    expect(output).to include("# HELP rails_health_check_latency_ms")
    expect(output).to include("# TYPE rails_health_check_latency_ms gauge")
  end

  it "emits latency lines for checks that have latency" do
    expect(output).to include('rails_health_check_latency_ms{check="database"} 3')
    expect(output).to include('rails_health_check_latency_ms{check="cache"} 12')
  end

  it "omits latency lines for checks with no latency" do
    expect(output).not_to include('rails_health_check_latency_ms{check="worker"}')
  end

  it "ends with a newline" do
    expect(output).to end_with("\n")
  end
end
