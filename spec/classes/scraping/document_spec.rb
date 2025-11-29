require 'rails_helper'

RSpec.describe Scraping::Document do
  let(:sample_html) do
    <<~HTML
      <!DOCTYPE html>
      <html>
        <head><title>Test Page</title></head>
        <body>
          <div id="bloqueImagenes">
            <a href="/link1" class="article">Article 1</a>
            <a href="/link2" class="article">Article 2</a>
          </div>
          <div id="content">
            <h1>Main Title</h1>
            <p class="intro">Introduction text</p>
            <article>
              <h2>Article Title</h2>
              <p>Article content</p>
            </article>
          </div>
        </body>
      </html>
    HTML
  end

  describe '.fetch' do
    let(:url) { 'https://example.com/page' }

    context 'when request is successful' do
      before do
        stub_request(:get, url)
          .to_return(status: 200, body: sample_html, headers: {})
      end

      it 'returns a Document instance' do
        doc = described_class.fetch(url)
        expect(doc).to be_a(Scraping::Document)
      end

      it 'stores the URL' do
        doc = described_class.fetch(url)
        expect(doc.url).to eq(url)
      end

      it 'parses the HTML content' do
        doc = described_class.fetch(url)
        expect(doc.title).to eq('Test Page')
      end
    end

    context 'when request fails' do
      before do
        stub_request(:get, url)
          .to_return(status: 404, body: 'Not Found')
      end

      it 'raises an error' do
        expect { described_class.fetch(url) }.to raise_error(/HTTP Error: 404/)
      end
    end
  end

  describe '#initialize' do
    it 'parses HTML content' do
      doc = described_class.new(sample_html)
      expect(doc.nokogiri_doc).to be_a(Nokogiri::HTML::Document)
    end

    it 'stores the URL if provided' do
      doc = described_class.new(sample_html, 'https://example.com')
      expect(doc.url).to eq('https://example.com')
    end

    it 'has nil URL if not provided' do
      doc = described_class.new(sample_html)
      expect(doc.url).to be_nil
    end
  end

  describe '#find_by_id' do
    let(:doc) { described_class.new(sample_html) }

    context 'when element exists' do
      it 'returns an ElementSet' do
        result = doc.find_by_id('bloqueImagenes')
        expect(result).to be_a(Scraping::ElementSet)
      end

      it 'finds the correct element' do
        result = doc.find_by_id('content')
        expect(result.text).to include('Main Title')
      end
    end

    context 'when element does not exist' do
      it 'returns nil' do
        result = doc.find_by_id('nonexistent')
        expect(result).to be_nil
      end
    end
  end

  describe '#find' do
    let(:doc) { described_class.new(sample_html) }

    context 'when element exists' do
      it 'returns an ElementSet with first matching element' do
        result = doc.find('a')
        expect(result).to be_a(Scraping::ElementSet)
        expect(result.attr('href')).to eq('/link1')
      end

      it 'finds by class selector' do
        result = doc.find('.intro')
        expect(result.text).to eq('Introduction text')
      end
    end

    context 'when element does not exist' do
      it 'returns nil' do
        result = doc.find('.nonexistent')
        expect(result).to be_nil
      end
    end
  end

  describe '#find_all' do
    let(:doc) { described_class.new(sample_html) }

    it 'returns an ElementSet with all matching elements' do
      result = doc.find_all('a')
      expect(result).to be_a(Scraping::ElementSet)
      expect(result.count).to eq(2)
    end

    it 'returns empty ElementSet when no matches' do
      result = doc.find_all('.nonexistent')
      expect(result).to be_a(Scraping::ElementSet)
      expect(result).to be_empty
    end

    it 'finds by complex selector' do
      result = doc.find_all('#bloqueImagenes a.article')
      expect(result.count).to eq(2)
    end
  end

  describe '#title' do
    let(:doc) { described_class.new(sample_html) }

    it 'returns the page title' do
      expect(doc.title).to eq('Test Page')
    end
  end

  describe '#text' do
    let(:doc) { described_class.new(sample_html) }

    it 'returns all text content' do
      text = doc.text
      expect(text).to include('Test Page')
      expect(text).to include('Article 1')
      expect(text).to include('Main Title')
    end
  end

  describe 'chaining example' do
    let(:doc) { described_class.new(sample_html) }

    it 'allows chaining from find_by_id to find_all' do
      links = doc.find_by_id('bloqueImagenes')
                 .find_all('a')

      expect(links.count).to eq(2)
      expect(links.pluck_attr('href')).to eq([ '/link1', '/link2' ])
    end
  end
end
