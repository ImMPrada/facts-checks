require 'rails_helper'

RSpec.describe Scraping::ColombiaCheckScraperService do
  let(:service) { described_class.new }
  let(:page_number) { 1 }
  let(:expected_url) { "https://colombiacheck.com/chequeos?page=#{page_number}" }

  describe '#get_list_of_fact_urls' do
    let(:mock_document) { instance_double(Scraping::Document) }
    let(:articles_container) { instance_double(Scraping::ElementSet) }

    before do
      allow(Scraping::Document).to receive(:fetch).and_return(mock_document)
    end

    context 'when articles are found' do
      let(:article_links) do
        instance_double(Scraping::ElementSet, empty?: false)
      end

      before do
        allow(mock_document).to receive(:find_by_id).with("bloqueImagenes").and_return(articles_container)
        allow(articles_container).to receive(:find_all).with("a").and_return(article_links)
      end

      it 'fetches the correct URL' do
        service.get_list_of_fact_urls(page_number)
        expect(Scraping::Document).to have_received(:fetch).with(expected_url)
      end

      it 'finds the bloqueImagenes container' do
        service.get_list_of_fact_urls(page_number)
        expect(mock_document).to have_received(:find_by_id).with("bloqueImagenes")
      end

      it 'finds all anchor tags within the container' do
        service.get_list_of_fact_urls(page_number)
        expect(articles_container).to have_received(:find_all).with("a")
      end

      it 'returns the article links' do
        result = service.get_list_of_fact_urls(page_number)
        expect(result).to eq(article_links)
      end
    end

    context 'when no articles are found' do
      let(:empty_article_links) do
        instance_double(Scraping::ElementSet, empty?: true)
      end

      before do
        allow(mock_document).to receive(:find_by_id).with("bloqueImagenes").and_return(articles_container)
        allow(articles_container).to receive(:find_all).with("a").and_return(empty_article_links)
      end

      it 'raises NoArticlesFoundError' do
        expect {
          service.get_list_of_fact_urls(page_number)
        }.to raise_error(Scraping::NoArticlesFoundError, "No articles found on page #{page_number}")
      end
    end

    context 'with different page numbers' do
      let(:article_links) do
        instance_double(Scraping::ElementSet, empty?: false)
      end

      before do
        allow(mock_document).to receive(:find_by_id).with("bloqueImagenes").and_return(articles_container)
        allow(articles_container).to receive(:find_all).with("a").and_return(article_links)
      end

      it 'builds URL correctly for page 5' do
        page_5_url = "https://colombiacheck.com/chequeos?page=5"

        service.get_list_of_fact_urls(5)
        expect(Scraping::Document).to have_received(:fetch).with(page_5_url)
      end

      it 'builds URL correctly for page 100' do
        page_100_url = "https://colombiacheck.com/chequeos?page=100"

        service.get_list_of_fact_urls(100)
        expect(Scraping::Document).to have_received(:fetch).with(page_100_url)
      end
    end
  end

  describe '#create_fact_urls' do
    let(:article_links) { instance_double(Scraping::ElementSet) }
    let(:urls) { [ "https://colombiacheck.com/article1", "https://colombiacheck.com/article2", "https://colombiacheck.com/article3" ] }

    before do
      allow(article_links).to receive(:pluck_attr).with("href").and_return(urls)
    end

    context 'when creating new records' do
      it 'creates FactCheckUrl records for each URL' do
        expect {
          service.create_fact_urls(article_links)
        }.to change { FactCheckUrl.count }.by(3)
      end

      it 'sets the source to colombia_check' do
        service.create_fact_urls(article_links)

        created_records = FactCheckUrl.where(url: urls)
        expect(created_records.pluck(:source).uniq).to eq([ "colombia_check" ])
      end

      it 'returns all created records' do
        result = service.create_fact_urls(article_links)

        expect(result.count).to eq(3)
        expect(result.all? { |r| r.is_a?(FactCheckUrl) }).to be true
        expect(result.map(&:url)).to match_array(urls)
      end

      it 'extracts href attributes from article links' do
        service.create_fact_urls(article_links)

        expect(article_links).to have_received(:pluck_attr).with("href")
      end
    end

    context 'when URLs already exist' do
      let!(:existing_record) { FactCheckUrl.create!(url: urls.first, source: :colombia_check) }

      it 'raises ActiveRecord::RecordInvalid error' do
        expect {
          service.create_fact_urls(article_links)
        }.to raise_error(ActiveRecord::RecordInvalid, /Url has already been taken/)
      end

      it 'does not create any new records when duplicate is encountered' do
        expect {
          service.create_fact_urls(article_links) rescue ActiveRecord::RecordInvalid
        }.not_to change { FactCheckUrl.count }
      end
    end
  end
end
