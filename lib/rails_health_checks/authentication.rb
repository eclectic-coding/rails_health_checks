# frozen_string_literal: true

require "ipaddr"

module RailsHealthChecks
  module Authentication
    def authenticate!
      config = RailsHealthChecks.configuration
      return unless auth_configured?(config)
      head :unauthorized unless authorized?(config)
    end

    private

    def auth_configured?(config)
      config.authenticate_block || config.token || config.allowed_ips
    end

    def authorized?(config)
      if config.authenticate_block
        config.authenticate_block.call(request)
      elsif config.token
        request.headers["Authorization"] == "Bearer #{config.token}"
      elsif config.allowed_ips
        ip_allowed?(config.allowed_ips)
      end
    end

    def ip_allowed?(allowed_ips)
      client_ip = IPAddr.new(request.ip)
      allowed_ips.any? { |entry| IPAddr.new(entry).include?(client_ip) }
    rescue IPAddr::InvalidAddressError
      false
    end
  end
end
