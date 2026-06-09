# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Health endpoints', type: :request do
  describe 'GET /health' do
    context 'when all checks pass' do
      it 'returns 200 with JSON body' do
        get '/health'

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('application/json')

        json = response.parsed_body
        expect(json['status']).to eq('ok')
        expect(json['timestamp']).to be_present
        expect(json['checks']['database']['status']).to eq('ok')
        expect(json['checks']['database']['latency_ms']).to be_a(Integer)
      end
    end

    context 'when the database check fails' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(StandardError, 'connection refused')
      end

      it 'returns 503 with critical status' do
        get '/health'

        expect(response).to have_http_status(:service_unavailable)

        json = response.parsed_body
        expect(json['status']).to eq('critical')
        expect(json['checks']['database']['status']).to eq('critical')
        expect(json['checks']['database']['message']).to eq('connection refused')
      end
    end
  end

  describe 'GET /health/:group' do
    before do
      RailsHealthChecks.configure { |c| c.group(:db_only, [:database]) }
    end

    after { RailsHealthChecks.instance_variable_set(:@configuration, nil) }

    context 'when the group exists' do
      it 'returns 200 with JSON body containing only the group checks' do
        get '/health/db_only'

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json['status']).to eq('ok')
        expect(json['checks'].keys).to eq(['database'])
      end

      context 'when a check in the group fails' do
        before do
          allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(StandardError, 'db down')
        end

        it 'returns 503' do
          get '/health/db_only'
          expect(response).to have_http_status(:service_unavailable)
          expect(response.parsed_body['status']).to eq('critical')
        end
      end
    end

    context 'when the group does not exist' do
      it 'returns 404 with an error message' do
        get '/health/nonexistent'

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body['error']).to match(/nonexistent/)
      end
    end
  end

  describe 'GET /health/metrics' do
    context 'when all checks pass' do
      it 'returns 200 with Prometheus content type' do
        get '/health/metrics'

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('text/plain')
        expect(response.content_type).to include('version=0.0.4')
      end

      it 'includes status gauge lines' do
        get '/health/metrics'

        expect(response.body).to include('# TYPE rails_health_check_status gauge')
        expect(response.body).to include('rails_health_check_status{check="database"}')
      end

      it 'always returns 200 even when a check is critical' do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(StandardError, 'db down')

        get '/health/metrics'

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('rails_health_check_status{check="database"} 2')
      end
    end
  end

  describe 'HEAD /health' do
    it 'returns 200 with no body' do
      head '/health'

      expect(response).to have_http_status(:ok)
      expect(response.body).to be_empty
    end

    context 'when the database check fails' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(StandardError, 'connection refused')
      end

      it 'returns 503 with no body' do
        head '/health'

        expect(response).to have_http_status(:service_unavailable)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'HEAD /health/live' do
    it 'returns 200 with no body' do
      head '/health/live'

      expect(response).to have_http_status(:ok)
      expect(response.body).to be_empty
    end
  end

  describe 'result caching' do
    after { RailsHealthChecks.instance_variable_set(:@result_cache, nil) }

    context 'when cache_duration is set' do
      before do
        RailsHealthChecks.configure { |c| c.cache_duration = 60 }
      end

      after { RailsHealthChecks.instance_variable_set(:@configuration, nil) }

      it 'returns the same result without re-running checks on a second request' do
        call_count = 0
        allow(ActiveRecord::Base.connection).to receive(:execute) { call_count += 1 }

        get '/health'
        get '/health'

        expect(call_count).to eq(1)
      end
    end

    context 'when cache_duration is nil (default)' do
      it 're-runs checks on every request' do
        call_count = 0
        allow(ActiveRecord::Base.connection).to receive(:execute) { call_count += 1 }

        get '/health'
        get '/health'

        expect(call_count).to eq(2)
      end
    end
  end

  describe 'GET /health/live' do
    context 'when all checks pass' do
      it 'returns 200 with OK text' do
        get '/health/live'

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('OK')
      end
    end

    context 'when the database check fails' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(StandardError, 'connection refused')
      end

      it 'returns 503 with Service Unavailable text' do
        get '/health/live'

        expect(response).to have_http_status(:service_unavailable)
        expect(response.body).to eq('Service Unavailable')
      end
    end
  end
end
