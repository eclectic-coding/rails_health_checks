# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RailsHealthChecks::ResponseBuilder do
  def make_check(status, latency_ms: nil, message: nil)
    check = RailsHealthChecks::Check.new
    check.instance_variable_set(:@status, status)
    check.instance_variable_set(:@latency_ms, latency_ms)
    check.instance_variable_set(:@message, message)
    check
  end

  describe '#overall_status' do
    it 'returns ok when all checks pass' do
      results = { database: make_check('ok') }
      expect(described_class.new(results).overall_status).to eq('ok')
    end

    it 'returns degraded when any check is degraded' do
      results = { database: make_check('ok'), cache: make_check('degraded') }
      expect(described_class.new(results).overall_status).to eq('degraded')
    end

    it 'returns critical when any check is critical' do
      results = { database: make_check('critical'), cache: make_check('degraded') }
      expect(described_class.new(results).overall_status).to eq('critical')
    end
  end

  describe '#http_status' do
    it 'returns :ok when overall status is ok' do
      results = { database: make_check('ok') }
      expect(described_class.new(results).http_status).to eq(:ok)
    end

    it 'returns :service_unavailable when overall status is not ok' do
      results = { database: make_check('critical') }
      expect(described_class.new(results).http_status).to eq(:service_unavailable)
    end
  end

  describe '#to_json' do
    it 'includes status, timestamp, and checks' do
      results = { database: make_check('ok', latency_ms: 5) }
      json = JSON.parse(described_class.new(results).to_json)

      expect(json['status']).to eq('ok')
      expect(json['timestamp']).to match(/\d{4}-\d{2}-\d{2}T/)
      expect(json['checks']['database']['status']).to eq('ok')
      expect(json['checks']['database']['latency_ms']).to eq(5)
    end

    it 'omits nil latency and message fields' do
      results = { database: make_check('ok') }
      json = JSON.parse(described_class.new(results).to_json)

      expect(json['checks']['database']).not_to have_key('latency_ms')
      expect(json['checks']['database']).not_to have_key('message')
    end

    it 'includes message when present' do
      results = { database: make_check('critical', message: 'DB down') }
      json = JSON.parse(described_class.new(results).to_json)

      expect(json['checks']['database']['message']).to eq('DB down')
    end
  end
end
