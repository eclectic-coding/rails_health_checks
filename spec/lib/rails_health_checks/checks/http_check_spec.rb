# frozen_string_literal: true

require "rails_helper"
require "net/http"

RSpec.describe RailsHealthChecks::Checks::HttpCheck do
  let(:url) { "http://example.com/status" }

  def stub_response(code)
    response = instance_double(Net::HTTPResponse, code: code.to_s)
    allow(Net::HTTP).to receive(:get_response).with(URI.parse(url)).and_return(response)
  end

  describe "#call" do
    context "when the response matches the expected status" do
      before { stub_response(200) }

      subject(:check) { described_class.new(url: url) }

      it "sets status to ok" do
        check.call
        expect(check.status).to eq("ok")
      end

      it "records latency in milliseconds" do
        check.call
        expect(check.latency_ms).to be_a(Integer)
        expect(check.latency_ms).to be >= 0
      end
    end

    context "when the response does not match the expected status" do
      before { stub_response(503) }

      subject(:check) { described_class.new(url: url) }

      it "sets status to critical" do
        check.call
        expect(check.status).to eq("critical")
      end

      it "includes the URL, actual code, and expected code in the message" do
        check.call
        expect(check.message).to eq("HTTP GET #{url} returned 503, expected 200")
      end
    end

    context "with a custom expected status" do
      subject(:check) { described_class.new(url: url, expected_status: 301) }

      context "when the response matches" do
        before { stub_response(301) }

        it "sets status to ok" do
          check.call
          expect(check.status).to eq("ok")
        end
      end

      context "when the response does not match" do
        before { stub_response(200) }

        it "sets status to critical" do
          check.call
          expect(check.status).to eq("critical")
        end

        it "references the custom expected status in the message" do
          check.call
          expect(check.message).to eq("HTTP GET #{url} returned 200, expected 301")
        end
      end
    end

    context "when a network error occurs" do
      before do
        allow(Net::HTTP).to receive(:get_response).and_raise(SocketError, "getaddrinfo: nodename nor servname provided")
      end

      subject(:check) { described_class.new(url: url) }

      it "sets status to critical" do
        check.call
        expect(check.status).to eq("critical")
      end

      it "records the error message" do
        check.call
        expect(check.message).to eq("getaddrinfo: nodename nor servname provided")
      end
    end
  end
end
