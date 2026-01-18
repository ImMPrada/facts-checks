require "rails_helper"

RSpec.describe ProcessPublicationDatesJob, type: :job do
  describe "#perform" do
    context "when there are publication dates with nil value" do
      let!(:publication_date) { create(:publication_date, value: nil) }
      let(:mock_service) { instance_double(PublicationDates::ParseDateService) }

      before do
        allow(PublicationDates::ParseDateService).to receive(:new)
          .with(publication_date)
          .and_return(mock_service)
        allow(mock_service).to receive(:call)
      end

      it "processes the first publication date" do
        expect(mock_service).to receive(:call)

        described_class.new.perform
      end

      it "enqueues itself again immediately" do
        expect(described_class).to receive(:perform_later)

        described_class.new.perform
      end

      it "logs the processing" do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:info)
          .with(/Processing PublicationDate##{publication_date.id}/)
        expect(Rails.logger).to receive(:info)
          .with(/Successfully processed PublicationDate##{publication_date.id}/)

        described_class.new.perform
      end
    end

    context "when there are no publication dates with nil value" do
      it "enqueues itself for 1 week later" do
        job_double = double("job")
        expect(described_class).to receive(:set).with(wait: 1.week).and_return(job_double)
        expect(job_double).to receive(:perform_later)

        described_class.new.perform
      end
    end

    context "when the service raises an error" do
      let!(:publication_date) { create(:publication_date, value: nil) }
      let(:mock_service) { instance_double(PublicationDates::ParseDateService) }

      before do
        allow(PublicationDates::ParseDateService).to receive(:new)
          .with(publication_date)
          .and_return(mock_service)
        allow(mock_service).to receive(:call)
          .and_raise(ParseDateError.new("Parse failed"))
      end

      it "logs the error" do
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)
        expect(Rails.logger).to receive(:error)
          .with(/Failed to process PublicationDate##{publication_date.id}/)

        expect { described_class.new.perform }
          .to raise_error(ParseDateError)
      end

      it "re-raises the error for retry mechanism" do
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)

        expect { described_class.new.perform }
          .to raise_error(ParseDateError)
      end
    end

    context "with multiple publication dates" do
      let!(:publication_date1) { create(:publication_date, value: nil, date: "2024-01-01") }
      let!(:publication_date2) { create(:publication_date, value: nil, date: "2024-01-02") }

      it "processes them one at a time" do
        service1 = instance_double(PublicationDates::ParseDateService)
        allow(PublicationDates::ParseDateService).to receive(:new)
          .with(publication_date1)
          .and_return(service1)
        allow(service1).to receive(:call)

        expect(service1).to receive(:call)
        allow(described_class).to receive(:perform_later)

        described_class.new.perform
      end
    end
  end
end
