# frozen_string_literal: true

require "rails_helper"
require "rails_health_checks/rack/app"

RSpec.describe RailsHealthChecks::Rack::App do
  let(:app)     { described_class }
  let(:browser) { Rack::MockRequest.new(app) }

  after { RailsHealthChecks.instance_variable_set(:@configuration, nil) }
  after { RailsHealthChecks.instance_variable_set(:@result_cache, nil) }

  describe "GET /" do
    it "returns 200 with JSON health body" do
      response = browser.get("/")

      expect(response.status).to eq(200)
      expect(response.content_type).to include("application/json")
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("ok")
      expect(body["timestamp"]).to be_truthy
      expect(body["checks"]["database"]["status"]).to eq("ok")
    end

    context "when a check fails" do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(StandardError, "connection refused")
      end

      it "returns 503 with critical status" do
        response = browser.get("/")

        expect(response.status).to eq(503)
        body = JSON.parse(response.body)
        expect(body["status"]).to eq("critical")
        expect(body["checks"]["database"]["message"]).to eq("connection refused")
      end
    end
  end

  describe "HEAD /" do
    it "returns 200 with no body" do
      response = browser.head("/")

      expect(response.status).to eq(200)
      expect(response.body).to be_empty
    end

    context "when a check fails" do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(StandardError, "db down")
      end

      it "returns 503 with no body" do
        response = browser.head("/")

        expect(response.status).to eq(503)
        expect(response.body).to be_empty
      end
    end
  end

  describe "GET /live" do
    it "returns 200 with plain OK" do
      response = browser.get("/live")

      expect(response.status).to eq(200)
      expect(response.content_type).to include("text/plain")
      expect(response.body).to eq("OK")
    end

    context "when a check fails" do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(StandardError, "db down")
      end

      it "returns 503 with Service Unavailable text" do
        response = browser.get("/live")

        expect(response.status).to eq(503)
        expect(response.body).to eq("Service Unavailable")
      end
    end
  end

  describe "HEAD /live" do
    it "returns 200 with no body" do
      response = browser.head("/live")

      expect(response.status).to eq(200)
      expect(response.body).to be_empty
    end
  end

  describe "GET /metrics" do
    it "returns 200 with Prometheus content type" do
      response = browser.get("/metrics")

      expect(response.status).to eq(200)
      expect(response.content_type).to include("text/plain")
      expect(response.content_type).to include("version=0.0.4")
    end

    it "includes status gauge lines" do
      response = browser.get("/metrics")

      expect(response.body).to include("# TYPE rails_health_check_status gauge")
      expect(response.body).to include('rails_health_check_status{check="database"}')
    end

    it "always returns 200 even when a check is critical" do
      allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(StandardError, "db down")

      response = browser.get("/metrics")

      expect(response.status).to eq(200)
      expect(response.body).to include('rails_health_check_status{check="database"} 2')
    end
  end

  describe "GET /:group" do
    before { RailsHealthChecks.configure { |c| c.group(:infra, [:database]) } }

    it "returns 200 with scoped JSON for a known group" do
      response = browser.get("/infra")

      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("ok")
      expect(body["checks"].keys).to eq(["database"])
    end

    it "returns 503 when a check in the group is critical" do
      allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(StandardError, "db down")

      response = browser.get("/infra")

      expect(response.status).to eq(503)
      expect(JSON.parse(response.body)["status"]).to eq("critical")
    end

    it "returns 404 for an unknown group" do
      response = browser.get("/nonexistent")

      expect(response.status).to eq(404)
      expect(JSON.parse(response.body)["error"]).to include("nonexistent")
    end
  end

  describe "unknown routes" do
    it "returns 404 for an unrecognized path" do
      response = browser.get("/unknown/nested/path")

      expect(response.status).to eq(404)
    end

    it "returns 404 for a POST request" do
      response = browser.post("/")

      expect(response.status).to eq(404)
    end
  end

  describe "token authentication" do
    before { RailsHealthChecks.configure { |c| c.token = "secret" } }

    it "returns 401 without a token" do
      response = browser.get("/")

      expect(response.status).to eq(401)
      expect(JSON.parse(response.body)["error"]).to eq("Unauthorized")
    end

    it "returns 401 with a wrong token" do
      response = browser.get("/", "HTTP_AUTHORIZATION" => "Bearer wrong")

      expect(response.status).to eq(401)
    end

    it "returns 200 with the correct bearer token" do
      response = browser.get("/", "HTTP_AUTHORIZATION" => "Bearer secret")

      expect(response.status).to eq(200)
    end
  end

  describe "IP allowlist authentication" do
    before { RailsHealthChecks.configure { |c| c.allowed_ips = ["127.0.0.1"] } }

    it "returns 200 for an allowed IP" do
      response = browser.get("/", "REMOTE_ADDR" => "127.0.0.1")

      expect(response.status).to eq(200)
    end

    it "returns 401 for a disallowed IP" do
      response = browser.get("/", "REMOTE_ADDR" => "10.0.0.1")

      expect(response.status).to eq(401)
    end

    it "returns 401 for an invalid IP address" do
      response = browser.get("/", "REMOTE_ADDR" => "not-an-ip")

      expect(response.status).to eq(401)
    end
  end

  describe "custom block authentication" do
    before do
      RailsHealthChecks.configure do |config|
        config.authenticate { |request| request.env["HTTP_X_INTERNAL"] == "true" }
      end
    end

    it "returns 200 when the block returns truthy" do
      response = browser.get("/", "HTTP_X_INTERNAL" => "true")

      expect(response.status).to eq(200)
    end

    it "returns 401 when the block returns falsy" do
      response = browser.get("/")

      expect(response.status).to eq(401)
    end
  end

  describe "result caching" do
    before { RailsHealthChecks.configure { |c| c.cache_duration = 60 } }

    it "does not re-run checks on a second request within the TTL" do
      call_count = 0
      allow(ActiveRecord::Base.connection).to receive(:execute) { call_count += 1 }

      browser.get("/")
      browser.get("/")

      expect(call_count).to eq(1)
    end
  end
end
