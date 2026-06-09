# frozen_string_literal: true

require "rails_helper"

RSpec.describe RailsHealthChecks::Checks::SmtpCheck do
  let(:smtp) { instance_double(Net::SMTP) }

  before do
    allow(Net::SMTP).to receive(:new).and_return(smtp)
    allow(smtp).to receive(:start).and_yield
  end

  describe "#call" do
    context "when the SMTP server is reachable" do
      subject(:check) { described_class.new(address: "mail.example.com", port: 587) }

      it "sets status to ok" do
        check.call
        expect(check.status).to eq("ok")
      end

      it "records latency in milliseconds" do
        check.call
        expect(check.latency_ms).to be_a(Integer)
        expect(check.latency_ms).to be >= 0
      end

      it "connects to the configured address and port" do
        check.call
        expect(Net::SMTP).to have_received(:new).with("mail.example.com", 587)
      end
    end

    context "when the SMTP server is unreachable" do
      subject(:check) { described_class.new(address: "mail.example.com", port: 25) }

      before { allow(smtp).to receive(:start).and_raise(Errno::ECONNREFUSED, "connection refused") }

      it "sets status to critical" do
        check.call
        expect(check.status).to eq("critical")
      end

      it "records the error message" do
        check.call
        expect(check.message).to be_present
      end
    end

    context "with no explicit address or port" do
      subject(:check) { described_class.new }

      context "when ActionMailer smtp_settings are configured" do
        before do
          allow(ActionMailer::Base).to receive(:smtp_settings)
            .and_return({ address: "smtp.myapp.com", port: 465 })
        end

        it "uses ActionMailer smtp_settings address and port" do
          check.call
          expect(Net::SMTP).to have_received(:new).with("smtp.myapp.com", 465)
        end
      end

      context "when ActionMailer smtp_settings have no address or port" do
        before do
          allow(ActionMailer::Base).to receive(:smtp_settings).and_return({})
        end

        it "falls back to localhost:25" do
          check.call
          expect(Net::SMTP).to have_received(:new).with("localhost", 25)
        end
      end

      context "when reading ActionMailer smtp_settings raises" do
        before do
          allow(ActionMailer::Base).to receive(:smtp_settings).and_raise(StandardError)
        end

        it "falls back to localhost:25" do
          check.call
          expect(Net::SMTP).to have_received(:new).with("localhost", 25)
        end
      end
    end
  end
end
