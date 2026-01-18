require 'rails_helper'

RSpec.describe ScrapeColombiaCheckJob, type: :job do
  let(:scraper) { instance_double(Scraping::ColombiaCheckScraperService) }
  let(:article_links) { instance_double(Scraping::ElementSet) }
  let(:created_records) { [ instance_double(FactCheckUrl), instance_double(FactCheckUrl) ] }

  before do
    allow(Scraping::ColombiaCheckScraperService).to receive(:new).and_return(scraper)
  end

  describe '#perform' do
    context 'when page_number is not provided' do
      it 'defaults to page 0' do
        allow(scraper).to receive(:get_list_of_fact_urls).with(0).and_return(article_links)
        allow(scraper).to receive(:create_fact_urls).with(article_links).and_return(created_records)
        allow(described_class).to receive(:set).and_return(described_class)
        allow(described_class).to receive(:perform_later)

        described_class.new.perform

        expect(scraper).to have_received(:get_list_of_fact_urls).with(0)
      end
    end

    context 'when scraping is successful' do
      let(:page_number) { 5 }

      before do
        allow(scraper).to receive(:get_list_of_fact_urls).with(page_number).and_return(article_links)
        allow(scraper).to receive(:create_fact_urls).with(article_links).and_return(created_records)
      end

      it 'fetches article links from the specified page' do
        allow(described_class).to receive(:set).and_return(described_class)
        allow(described_class).to receive(:perform_later)

        described_class.new.perform(page_number)

        expect(scraper).to have_received(:get_list_of_fact_urls).with(page_number)
      end

      it 'creates FactCheckUrl records from the article links' do
        allow(described_class).to receive(:set).and_return(described_class)
        allow(described_class).to receive(:perform_later)

        described_class.new.perform(page_number)

        expect(scraper).to have_received(:create_fact_urls).with(article_links)
      end

      it 're-enqueues itself with page_number + 1' do
        allow(described_class).to receive(:set).and_return(described_class)
        allow(described_class).to receive(:perform_later)

        described_class.new.perform(page_number)

        expect(described_class).to have_received(:perform_later).with(page_number + 1)
      end

      it 'schedules the next job with a random delay between 10-20 seconds' do
        allow(described_class).to receive(:perform_later)

        # Stub rand to return a specific value for testing
        allow_any_instance_of(Object).to receive(:rand).with(10..20).and_return(2)

        expect(described_class).to receive(:set).with(wait: 2.seconds).and_return(described_class)

        described_class.new.perform(page_number)
      end
    end

    context 'when ActiveRecord::RecordInvalid is raised' do
      let(:page_number) { 10 }
      let(:error) { ActiveRecord::RecordInvalid.new }

      before do
        allow(scraper).to receive(:get_list_of_fact_urls).with(page_number).and_return(article_links)
        allow(scraper).to receive(:create_fact_urls).with(article_links).and_raise(error)
        allow(Rails.logger).to receive(:info)
        allow(described_class).to receive(:set).and_return(described_class)
        allow(described_class).to receive(:perform_later)
      end

      it 're-enqueues the job with default page_number (0)' do
        described_class.new.perform(page_number)

        expect(described_class).to have_received(:perform_later).with(no_args)
      end

      it 'schedules the job for 1 week later' do
        described_class.new.perform(page_number)

        expect(described_class).to have_received(:set).with(wait: 1.week)
      end

      it 'logs the error message with re-enqueueing info' do
        described_class.new.perform(page_number)

        expect(Rails.logger).to have_received(:info).with(/ScrapeColombiaCheckJob stopped at page #{page_number}.*Re-enqueueing in 1 week/)
      end

      it 'does not raise the error' do
        expect {
          described_class.new.perform(page_number)
        }.not_to raise_error
      end
    end

    context 'when Scraping::NoArticlesFoundError is raised' do
      let(:page_number) { 15 }
      let(:error) { Scraping::NoArticlesFoundError.new("No articles found") }

      before do
        allow(scraper).to receive(:get_list_of_fact_urls).with(page_number).and_raise(error)
        allow(Rails.logger).to receive(:info)
        allow(described_class).to receive(:set).and_return(described_class)
        allow(described_class).to receive(:perform_later)
      end

      it 're-enqueues the job with default page_number (0)' do
        described_class.new.perform(page_number)

        expect(described_class).to have_received(:perform_later).with(no_args)
      end

      it 'schedules the job for 1 week later' do
        described_class.new.perform(page_number)

        expect(described_class).to have_received(:set).with(wait: 1.week)
      end

      it 'logs the error message with re-enqueueing info' do
        described_class.new.perform(page_number)

        expect(Rails.logger).to have_received(:info).with(/ScrapeColombiaCheckJob stopped at page #{page_number}.*Re-enqueueing in 1 week/)
      end

      it 'does not raise the error' do
        expect {
          described_class.new.perform(page_number)
        }.not_to raise_error
      end
    end

    context 'integration with ActiveJob' do
      it 'enqueues the job' do
        allow(scraper).to receive(:get_list_of_fact_urls).and_return(article_links)
        allow(scraper).to receive(:create_fact_urls).and_return(created_records)

        expect {
          described_class.perform_later(1)
        }.to have_enqueued_job(described_class).with(1).on_queue("default")
      end
    end
  end
end
