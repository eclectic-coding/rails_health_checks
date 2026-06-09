# frozen_string_literal: true

module RailsHealthChecks
  class Configuration
    attr_writer :checks
    attr_accessor :timeout, :allowed_ips, :token, :sidekiq_queue_size, :solid_queue_job_count, :good_job_latency,
                  :resque_queue_size, :disk_warn_threshold, :disk_critical_threshold, :disk_path,
                  :memory_threshold, :http_url, :http_expected_status
    attr_reader :authenticate_block, :custom_checks, :groups

    def initialize
      @checks = [:database]
      @timeout = 5
      @allowed_ips = nil
      @token = nil
      @authenticate_block = nil
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
      @custom_checks = {}
      @groups = {}
      @disabled_checks = {}
    end

    def checks
      disabled = @disabled_checks.filter_map { |name, envs| name if envs.include?(Rails.env.to_s) }
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

    def register(name, check)
      @custom_checks[name] = check
      @checks << name unless @checks.include?(name)
    end
  end
end
