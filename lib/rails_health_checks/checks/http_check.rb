# frozen_string_literal: true

require "net/http"
require "uri"

module RailsHealthChecks
  module Checks
    class HttpCheck < Check
      def initialize(url:, expected_status: 200, headers: {})
        @url = url
        @expected_status = expected_status
        @headers = headers
      end

      def call
        measure do
          uri = URI.parse(@url)
          request = Net::HTTP::Get.new(uri)
          @headers.each { |name, value| request[name] = value }
          response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(request) }
          code = response.code.to_i
          return fail_with("HTTP GET #{@url} returned #{code}, expected #{@expected_status}") if code != @expected_status
        end
        pass
      rescue StandardError => e
        fail_with(e.message)
      end
    end
  end
end
