# frozen_string_literal: true

require "net/smtp"

module RailsHealthChecks
  module Checks
    class SmtpCheck < Check
      def initialize(address: nil, port: nil)
        @address = address
        @port    = port
      end

      def call
        measure do
          smtp = Net::SMTP.new(resolved_address, resolved_port)
          smtp.start { }
        end
        pass
      rescue StandardError => e
        fail_with(e.message)
      end

      private

      def resolved_address
        @address ||
          actionmailer_setting(:address) ||
          "localhost"
      end

      def resolved_port
        @port ||
          actionmailer_setting(:port) ||
          25
      end

      def actionmailer_setting(key)
        return unless defined?(::ActionMailer::Base)

        ::ActionMailer::Base.smtp_settings[key]
      rescue StandardError
        nil
      end
    end
  end
end
