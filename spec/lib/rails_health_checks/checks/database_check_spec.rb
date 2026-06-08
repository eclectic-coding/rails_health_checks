# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RailsHealthChecks::Checks::DatabaseCheck do
  subject(:check) { described_class.new }

  describe '#call' do
    context 'when the database is reachable' do
      it 'sets status to ok' do
        check.call
        expect(check.status).to eq('ok')
      end

      it 'records latency in milliseconds' do
        check.call
        expect(check.latency_ms).to be_a(Integer)
        expect(check.latency_ms).to be >= 0
      end
    end

    context 'when the database raises an error' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(StandardError, 'DB unavailable')
      end

      it 'sets status to critical' do
        check.call
        expect(check.status).to eq('critical')
      end

      it 'records the error message' do
        check.call
        expect(check.message).to eq('DB unavailable')
      end
    end
  end
end
