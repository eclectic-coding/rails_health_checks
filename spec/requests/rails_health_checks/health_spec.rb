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
