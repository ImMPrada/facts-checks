require 'rails_helper'

RSpec.describe MineFactCheckUrlJob, type: :job do
  let(:scraper) { instance_double(Scraping::ColombiaCheckScraperService) }
  let(:creation_service) { instance_double(FactCheck::CreationService) }
  let(:fact_check) { instance_double(FactCheck, id: 123) }
  let(:fact_check_url) { create(:fact_check_url, url: "/chequeos/test-article", source: :colombia_check, digested: false) }
  let(:fact_data) do
    {
      source_url: "https://colombiacheck.com/chequeos/test-article",
      veredict: "Falso",
      title: "Test Title",
      reasoning: "Test reasoning"
    }
  end

  before do
    allow(Scraping::ColombiaCheckScraperService).to receive(:new).and_return(scraper)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:debug)
    allow(Rails.logger).to receive(:error)
  end

  describe '#perform' do
    context 'when there are no undigested URLs' do
      before do
        allow(described_class).to receive(:set).and_return(described_class)
        allow(described_class).to receive(:perform_later)
        allow(scraper).to receive(:mine_fact)
      end

      it 'logs that no undigested URLs were found' do
        described_class.new.perform

        expect(Rails.logger).to have_received(:info).with(/No undigested URLs found/)
      end

      it 're-enqueues the job for 1 week later' do
        described_class.new.perform

        expect(described_class).to have_received(:set).with(wait: 1.week)
        expect(described_class).to have_received(:perform_later).with(no_args)
      end

      it 'does not attempt to scrape' do
        described_class.new.perform

        expect(scraper).not_to have_received(:mine_fact)
      end
    end

    context 'when there is an undigested URL' do
      before do
        fact_check_url # Create the record
        allow(described_class).to receive(:set).and_return(described_class)
        allow(described_class).to receive(:perform_later)
      end

      context 'and scraping is successful' do
        before do
          allow(scraper).to receive(:mine_fact).with(fact_check_url.full_url).and_return(fact_data)
          allow(FactCheck::CreationService).to receive(:new).with(fact_data).and_return(creation_service)
          allow(creation_service).to receive(:build)
          allow(creation_service).to receive(:save!).and_return(fact_check)
        end

        it 'scrapes the URL using full_url' do
          described_class.new.perform

          expect(scraper).to have_received(:mine_fact).with("https://colombiacheck.com/chequeos/test-article")
        end

        it 'creates a FactCheck using the CreationService' do
          described_class.new.perform

          expect(FactCheck::CreationService).to have_received(:new).with(fact_data)
          expect(creation_service).to have_received(:build)
          expect(creation_service).to have_received(:save!)
        end

        it 'logs the successful FactCheck creation' do
          described_class.new.perform

          expect(Rails.logger).to have_received(:info).with(/Successfully created FactCheck #123/)
        end

        it 'marks the FactCheckUrl as digested' do
          expect {
            described_class.new.perform
          }.to change { fact_check_url.reload.digested }.from(false).to(true)
        end

        it 'sets the digested_at timestamp' do
          Timecop.freeze do
            expect {
              described_class.new.perform
            }.to change { fact_check_url.reload.digested_at }.from(nil).to(be_within(1.second).of(Time.current))
          end
        end

        it 're-enqueues the job with a random delay between 10-20 seconds' do
          allow_any_instance_of(Object).to receive(:rand).with(10..20).and_return(15)

          described_class.new.perform

          expect(described_class).to have_received(:set).with(wait: 15.seconds)
          expect(described_class).to have_received(:perform_later).with(no_args)
        end
      end

      context 'and scraping fails' do
        let(:error_message) { "Network error" }

        before do
          allow(scraper).to receive(:mine_fact).with(fact_check_url.full_url).and_raise(StandardError, error_message)
        end

        it 'marks the FactCheckUrl as failed' do
          expect {
            described_class.new.perform
          }.to change { fact_check_url.reload.last_error }.from(nil).to(error_message)
        end

        it 'increments the attempts counter' do
          expect {
            described_class.new.perform
          }.to change { fact_check_url.reload.attempts }.from(0).to(1)
        end

        it 'does not mark the URL as digested' do
          expect {
            described_class.new.perform
          }.not_to change { fact_check_url.reload.digested }
        end

        it 'logs the error' do
          described_class.new.perform

          expect(Rails.logger).to have_received(:error).with(/Failed to process.*#{error_message}/)
        end

        it 're-enqueues the job with a random delay between 10-20 seconds' do
          allow_any_instance_of(Object).to receive(:rand).with(10..20).and_return(12)

          described_class.new.perform

          expect(described_class).to have_received(:set).with(wait: 12.seconds)
          expect(described_class).to have_received(:perform_later).with(no_args)
        end

        it 'does not raise the error' do
          allow(described_class).to receive(:set).and_return(described_class)
          allow(described_class).to receive(:perform_later)

          expect {
            described_class.new.perform
          }.not_to raise_error
        end
      end
    end

    context 'integration with ActiveJob' do
      it 'enqueues the job' do
        expect {
          described_class.perform_later
        }.to have_enqueued_job(described_class).with(no_args).on_queue("default")
      end
    end
  end
end
