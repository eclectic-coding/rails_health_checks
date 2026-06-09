# frozen_string_literal: true

require "net/http"
require "uri"

module RailsHealthChecks
  module Checks
    class HttpCheck < Check
      def initialize(url:, expected_status: 200)
        @url = url
        @expected_status = expected_status
      end

      def call
        measure do
          response = Net::HTTP.get_response(URI.parse(@url))
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
