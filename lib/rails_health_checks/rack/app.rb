# frozen_string_literal: true

require "ipaddr"
require "json"
require "rack"

module RailsHealthChecks
  module Rack
    # Mountable Rack app exposing the same endpoints as the Rails engine.
    # Mount in config.ru:
    #
    #   require "rails_health_checks/rack/app"
    #   map "/health" { run RailsHealthChecks::Rack::App }
    #
    # Or in Sinatra/Roda via their mount helpers.
    #
    # Available routes (relative to mount point):
    #   GET/HEAD /          → JSON health (same shape as Rails engine)
    #   GET/HEAD /live      → plain-text liveness probe
    #   GET      /metrics   → Prometheus text format
    #   GET      /:group    → scoped group JSON
    class App
      def self.call(env)
        new(env).call
      end

      def initialize(env)
        @env = env
        @request = ::Rack::Request.new(env)
      end

      def call
        return unauthorized unless authorized?

        response = dispatch
        @request.head? ? [response[0], response[1], []] : response
      end

      def dispatch
        path   = @request.path_info.delete_suffix("/")
        method = @request.request_method

        case [method, path]
        when ["GET", ""], ["HEAD", ""]
          health_response
        when ["GET", "/live"], ["HEAD", "/live"]
          live_response
        when ["GET", "/metrics"]
          metrics_response
        else
          if %w[GET HEAD].include?(method) && (m = path.match(%r{\A/([^/]+)\z}))
            group_response(m[1])
          else
            not_found
          end
        end
      end

      private

      def run_checks(check_names)
        config = RailsHealthChecks.configuration
        if config.cache_duration
          cache_key = check_names.map(&:to_s).sort.join(",")
          RailsHealthChecks.result_cache.fetch(cache_key, ttl: config.cache_duration) do
            build_and_run(check_names, config)
          end
        else
          build_and_run(check_names, config)
        end
      end

      def build_and_run(check_names, config)
        checks = CheckRegistry.build(check_names)
        CheckRegistry.run(checks, timeout: config.timeout)
      end

      def health_response
        builder = ResponseBuilder.new(run_checks(RailsHealthChecks.configuration.checks))
        json(builder.http_status == :ok ? 200 : 503, builder.to_json)
      end

      def live_response
        builder = ResponseBuilder.new(run_checks(RailsHealthChecks.configuration.checks))
        if builder.overall_status == "ok"
          plain(200, "OK")
        else
          plain(503, "Service Unavailable")
        end
      end

      def metrics_response
        results = run_checks(RailsHealthChecks.configuration.checks)
        [200, { "Content-Type" => "text/plain; version=0.0.4" }, [PrometheusFormatter.new(results).to_text]]
      end

      def group_response(id)
        group_name  = id.to_sym
        check_names = RailsHealthChecks.configuration.groups[group_name]
        return not_found("Group '#{group_name}' not found") unless check_names

        builder = ResponseBuilder.new(run_checks(check_names))
        json(builder.http_status == :ok ? 200 : 503, builder.to_json)
      end

      def authorized?
        config = RailsHealthChecks.configuration
        return true unless config.authenticate_block || config.token || config.allowed_ips

        if config.authenticate_block
          config.authenticate_block.call(@request)
        elsif config.token
          @env["HTTP_AUTHORIZATION"] == "Bearer #{config.token}"
        elsif config.allowed_ips
          ip_allowed?(config.allowed_ips)
        end
      end

      def ip_allowed?(allowed_ips)
        client_ip = IPAddr.new(@request.ip)
        allowed_ips.any? { |entry| IPAddr.new(entry).include?(client_ip) }
      rescue IPAddr::InvalidAddressError
        false
      end

      def json(status, body)
        [status, { "Content-Type" => "application/json" }, [body]]
      end

      def plain(status, body)
        [status, { "Content-Type" => "text/plain" }, [body]]
      end

      def unauthorized
        json(401, { error: "Unauthorized" }.to_json)
      end

      def not_found(message = "Not found")
        json(404, { error: message }.to_json)
      end
    end
  end
end
