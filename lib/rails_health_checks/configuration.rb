# frozen_string_literal: true

module RailsHealthChecks
  class ConfigurationError < StandardError; end

  class Configuration
    BUILT_IN_NAMES = %i[database cache redis sidekiq solid_queue good_job resque disk memory http smtp].freeze

    attr_writer :checks
    attr_accessor :timeout, :cache_duration, :allowed_ips, :token,
                  :redis_url,
                  :smtp_address, :smtp_port,
                  :sidekiq_queue_size, :solid_queue_job_count, :good_job_latency,
                  :resque_queue_size, :disk_warn_threshold, :disk_critical_threshold, :disk_path,
                  :memory_threshold, :http_url, :http_expected_status, :http_headers,
                  :readiness_path
    attr_reader :authenticate_block, :custom_checks, :groups

    def initialize
      @checks = [:database]
      @timeout = 5
      @cache_duration = nil
      @allowed_ips = nil
      @token = nil
      @authenticate_block = nil
      @redis_url = nil
      @smtp_address = nil
      @smtp_port = nil
      @sidekiq_queue_size = nil
      @solid_queue_job_count = nil
      @good_job_latency = nil
      @resque_queue_size = nil
      @disk_warn_threshold = nil
      @disk_critical_threshold = nil
      @disk_path = "/"
      @memory_threshold = nil
      @http_url = nil
      @http_expected_status = 200
      @http_headers = {}
      @custom_checks = {}
      @groups = {}
      @disabled_checks = {}
      @readiness_path = "ready"
    end

    def checks
      current_env = defined?(Rails) ? Rails.env.to_s : ENV.fetch("RACK_ENV", "production")
      disabled = @disabled_checks.filter_map { |name, envs| name if envs.include?(current_env) }
      @checks - disabled
    end

    def authenticate(&block)
      @authenticate_block = block
    end

    def disable(name, **opts)
      envs = Array(opts.fetch(:in)).map(&:to_s)
      @disabled_checks[name] ||= []
      @disabled_checks[name].concat(envs)
    end

    def group(name, check_names)
      @groups[name] = check_names
    end

    def register(name, check, timeout: nil)
      check.timeout = timeout
      @custom_checks[name] = check
      @checks << name unless @checks.include?(name)
    end

    def validate!
      all_checks = @checks + @groups.values.flatten
      all_checks.uniq.each do |name|
        next if BUILT_IN_NAMES.include?(name) || @custom_checks.key?(name)

        raise ConfigurationError, "Unknown check :#{name}. Built-ins: #{BUILT_IN_NAMES.join(', ')}"
      end

      if @checks.include?(:http) && @http_url.nil?
        raise ConfigurationError, "config.checks includes :http but config.http_url is not set"
      end
    end
  end
end
