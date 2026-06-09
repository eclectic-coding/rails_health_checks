# frozen_string_literal: true

module RailsHealthChecks
  class Configuration
    attr_accessor :checks, :timeout, :allowed_ips, :token, :sidekiq_queue_size, :solid_queue_job_count, :good_job_latency
    attr_reader :authenticate_block

    def initialize
      @checks = [:database]
      @timeout = 5
      @allowed_ips = nil
      @token = nil
      @authenticate_block = nil
      @sidekiq_queue_size = nil
      @solid_queue_job_count = nil
      @good_job_latency = nil
    end

    def authenticate(&block)
      @authenticate_block = block
    end
  end
end
