require "rails_helper"

RSpec.describe PublicationDates::ParseDateService do
  let(:publication_date) { create(:publication_date, date: "2024-01-15 20:00:00") }
  let(:mock_openai_client) { instance_double(Openai::Client) }
  let(:service) { described_class.new(publication_date, openai_client: mock_openai_client) }

  describe "#call" do
    context "when date is successfully parsed" do
      before do
        allow(mock_openai_client).to receive(:chat).and_return("2024-01-16")
      end

      it "updates the publication_date value" do
        expect { service.call }
          .to change { publication_date.reload.value }
          .from(nil)
          .to(Date.parse("2024-01-16"))
      end

      it "returns the parsed date" do
        result = service.call
        expect(result).to eq(Date.parse("2024-01-16"))
      end

      it "sends correct messages to OpenAI" do
        expect(mock_openai_client).to receive(:chat).with(
          messages: array_including(
            hash_including(role: "system"),
            { role: "user", content: "2024-01-15 20:00:00" }
          ),
          temperature: 0.0
        )

        service.call
      end
    end

    context "when publication_date.date is blank" do
      let(:publication_date) { build_stubbed(:publication_date, date: nil) }

      it "does not call OpenAI" do
        expect(mock_openai_client).not_to receive(:chat)
        service.call
      end

      it "returns nil" do
        result = service.call
        expect(result).to be_nil
      end
    end

    context "when OpenAI returns INVALID" do
      before do
        allow(mock_openai_client).to receive(:chat).and_return("INVALID")
      end

      it "raises an error" do
        expect { service.call }
          .to raise_error(PublicationDates::Errors::ParseDateServiceError, /could not parse the date/)
      end
    end

    context "when OpenAI returns invalid date format" do
      before do
        allow(mock_openai_client).to receive(:chat).and_return("not a date")
      end

      it "raises an error" do
        expect { service.call }
          .to raise_error(PublicationDates::Errors::ParseDateServiceError, /Invalid date format/)
      end
    end

    context "when date year is out of range" do
      before do
        allow(mock_openai_client).to receive(:chat).and_return("1800-01-15")
      end

      it "raises an error" do
        expect { service.call }
          .to raise_error(PublicationDates::Errors::ParseDateServiceError, /year out of reasonable range/)
      end
    end

    context "when OpenAI client raises an error" do
      before do
        allow(mock_openai_client).to receive(:chat)
          .and_raise(Openai::Errors::ClientError.new("API error"))
      end

      it "logs the error" do
        allow(Rails.logger).to receive(:error)
        expect(Rails.logger).to receive(:error).with(/Failed to parse date/)

        expect { service.call }.to raise_error(PublicationDates::Errors::ParseDateServiceError)
      end

      it "raises a ParseDateService error" do
        expect { service.call }
          .to raise_error(PublicationDates::Errors::ParseDateServiceError, /Failed to parse date/)
      end
    end

    context "with different date formats" do
      it "handles date with time that crosses midnight to UTC" do
        publication_date.update!(date: "2024-01-15 23:00:00")
        allow(mock_openai_client).to receive(:chat).and_return("2024-01-16")

        service.call
        expect(publication_date.reload.value).to eq(Date.parse("2024-01-16"))
      end

      it "handles date with time that stays same day in UTC" do
        publication_date.update!(date: "2024-01-15 10:00:00")
        allow(mock_openai_client).to receive(:chat).and_return("2024-01-15")

        service.call
        expect(publication_date.reload.value).to eq(Date.parse("2024-01-15"))
      end

      it "handles date without time" do
        publication_date.update!(date: "2024-01-15")
        allow(mock_openai_client).to receive(:chat).and_return("2024-01-15")

        service.call
        expect(publication_date.reload.value).to eq(Date.parse("2024-01-15"))
      end
    end
  end
end
