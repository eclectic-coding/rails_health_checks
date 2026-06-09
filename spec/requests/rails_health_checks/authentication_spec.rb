# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication", type: :request do
  after { RailsHealthChecks.instance_variable_set(:@configuration, nil) }

  context "when no auth is configured" do
    it "allows access to GET /health" do
      get "/health"
      expect(response).to have_http_status(:ok)
    end
  end

  context "with bearer token auth" do
    before { RailsHealthChecks.configure { |c| c.token = "secret" } }

    it "allows access with correct token" do
      get "/health", headers: { "Authorization" => "Bearer secret" }
      expect(response).to have_http_status(:ok)
    end

    it "rejects missing token with 401" do
      get "/health"
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects wrong token with 401" do
      get "/health", headers: { "Authorization" => "Bearer wrong" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with IP allowlist auth" do
    before { RailsHealthChecks.configure { |c| c.allowed_ips = ["127.0.0.1"] } }

    it "allows access from an allowed IP" do
      get "/health", env: { "REMOTE_ADDR" => "127.0.0.1" }
      expect(response).to have_http_status(:ok)
    end

    it "rejects access from a non-allowed IP with 401" do
      get "/health", env: { "REMOTE_ADDR" => "1.2.3.4" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with CIDR allowlist auth" do
    before { RailsHealthChecks.configure { |c| c.allowed_ips = ["10.0.0.0/8"] } }

    it "allows access from an IP in the CIDR range" do
      get "/health", env: { "REMOTE_ADDR" => "10.1.2.3" }
      expect(response).to have_http_status(:ok)
    end

    it "rejects access from an IP outside the CIDR range with 401" do
      get "/health", env: { "REMOTE_ADDR" => "192.168.1.1" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with an invalid IP entry in allowed_ips" do
    before { RailsHealthChecks.configure { |c| c.allowed_ips = ["not-a-valid-ip"] } }

    it "rejects access with 401 rather than raising" do
      get "/health"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with custom authenticate block" do
    before do
      RailsHealthChecks.configure do |c|
        c.authenticate { |req| req.headers["X-Internal"] == "true" }
      end
    end

    it "allows access when block returns true" do
      get "/health", headers: { "X-Internal" => "true" }
      expect(response).to have_http_status(:ok)
    end

    it "rejects access when block returns false with 401" do
      get "/health"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
