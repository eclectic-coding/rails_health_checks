# frozen_string_literal: true

module RailsHealthChecks
  class ApplicationMailer < ActionMailer::Base
    default from: 'from@example.com'
    layout 'mailer'
  end
end
