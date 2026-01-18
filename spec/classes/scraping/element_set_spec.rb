require 'rails_helper'

RSpec.describe Scraping::ElementSet do
  let(:sample_html) do
    <<~HTML
      <div id="container">
        <div id="article1" class="article">
          <h2>Title 1</h2>
          <a href="/link1" data-id="1">Link 1</a>
          <p>Content 1</p>
        </div>
        <div id="article2" class="article">
          <h2>Title 2</h2>
          <a href="/link2" data-id="2">Link 2</a>
          <p>Content 2</p>
        </div>
        <div class="footer">
          <span>Footer text</span>
        </div>
      </div>
    HTML
  end

  let(:doc) { Nokogiri::HTML(sample_html) }
  let(:articles) { doc.css('.article').to_a }
  let(:element_set) { described_class.new(articles) }

  describe '#initialize' do
    it 'accepts an array of elements' do
      expect { described_class.new(articles) }.not_to raise_error
    end

    it 'accepts a single element' do
      single = doc.at_css('.article')
      set = described_class.new(single)
      expect(set.count).to eq(1)
    end

    it 'stores elements' do
      expect(element_set.elements).to eq(articles.to_a)
    end
  end

  describe '#find_by_id' do
    let(:container_html) do
      <<~HTML
        <div id="wrapper">
          <div id="inner1">Content 1</div>
          <div id="inner2">Content 2</div>
        </div>
      HTML
    end
    let(:container_doc) { Nokogiri::HTML(container_html) }
    let(:container_set) { described_class.new(container_doc.css('#wrapper').to_a) }

    context 'when element exists' do
      it 'returns an ElementSet' do
        result = container_set.find_by_id('inner1')
        expect(result).to be_a(Scraping::ElementSet)
      end

      it 'finds the correct element' do
        result = container_set.find_by_id('inner1')
        expect(result.text).to eq('Content 1')
      end
    end

    context 'when element does not exist' do
      it 'returns nil' do
        result = container_set.find_by_id('nonexistent')
        expect(result).to be_nil
      end
    end
  end

  describe '#find' do
    it 'returns first matching element' do
      result = element_set.find('a')
      expect(result).to be_a(Scraping::ElementSet)
      expect(result.attr('href')).to eq('/link1')
    end

    it 'returns nil when no match' do
      result = element_set.find('.nonexistent')
      expect(result).to be_nil
    end
  end

  describe '#find_all' do
    it 'returns all matching elements' do
      result = element_set.find_all('a')
      expect(result.count).to eq(2)
    end

    it 'returns empty ElementSet when no matches' do
      result = element_set.find_all('.nonexistent')
      expect(result).to be_empty
    end
  end

  describe '#find_by_tag' do
    it 'finds all elements by tag name' do
      result = element_set.find_by_tag('h2')
      expect(result.count).to eq(2)
      expect(result.map(&:text)).to eq([ 'Title 1', 'Title 2' ])
    end
  end

  describe '#text' do
    it 'returns text from first element' do
      result = element_set.find_all('h2')
      expect(result.text).to eq('Title 1')
    end

    it 'strips whitespace' do
      html = '<p>  Some text  </p>'
      doc = Nokogiri::HTML(html)
      set = described_class.new(doc.css('p'))
      expect(set.text).to eq('Some text')
    end
  end

  describe '#all_text' do
    it 'returns text from all elements joined' do
      result = element_set.find_all('h2')
      expect(result.all_text).to eq('Title 1 Title 2')
    end
  end

  describe '#inner_html' do
    it 'returns HTML content of first element' do
      html = element_set.inner_html
      expect(html).to include('<h2>Title 1</h2>')
      expect(html).to include('<a href="/link1"')
    end
  end

  describe '#attr' do
    it 'returns attribute value from first element' do
      result = element_set.find_all('a')
      expect(result.attr('href')).to eq('/link1')
    end

    it 'returns data attribute' do
      result = element_set.find_all('a')
      expect(result.attr('data-id')).to eq('1')
    end

    it 'returns nil when attribute does not exist' do
      result = element_set.find_all('a')
      expect(result.attr('nonexistent')).to be_nil
    end
  end

  describe '#pluck_attr' do
    it 'returns array of attribute values from all elements' do
      result = element_set.find_all('a')
      expect(result.pluck_attr('href')).to eq([ '/link1', '/link2' ])
    end

    it 'returns array of data attributes' do
      result = element_set.find_all('a')
      expect(result.pluck_attr('data-id')).to eq([ '1', '2' ])
    end

    it 'excludes nil values' do
      result = element_set.find_all('p')
      expect(result.pluck_attr('href')).to eq([])
    end
  end

  describe '#empty? and #present?' do
    it 'returns true when no elements' do
      empty_set = described_class.new([])
      expect(empty_set).to be_empty
      expect(empty_set).not_to be_present
    end

    it 'returns false when has elements' do
      expect(element_set).not_to be_empty
      expect(element_set).to be_present
    end
  end

  describe '#first and #last' do
    it 'returns first element' do
      expect(element_set.first).to eq(articles[0])
    end

    it 'returns last element' do
      expect(element_set.last).to eq(articles[1])
    end
  end

  describe '#count, #size, #length' do
    it 'returns element count' do
      expect(element_set.count).to eq(2)
      expect(element_set.size).to eq(2)
      expect(element_set.length).to eq(2)
    end
  end

  describe '#map' do
    it 'maps over elements' do
      result = element_set.map { |el| el.css('h2').text }
      expect(result).to eq([ 'Title 1', 'Title 2' ])
    end
  end

  describe '#select' do
    it 'filters elements and returns ElementSet' do
      result = element_set.select { |el| el.attr('id') == 'article1' }
      expect(result).to be_a(Scraping::ElementSet)
      expect(result.count).to eq(1)
      expect(result.text).to include('Title 1')
    end
  end

  describe '#reject' do
    it 'rejects elements and returns ElementSet' do
      result = element_set.reject { |el| el.attr('id') == 'article1' }
      expect(result).to be_a(Scraping::ElementSet)
      expect(result.count).to eq(1)
      expect(result.text).to include('Title 2')
    end
  end

  describe '#each' do
    it 'iterates over elements' do
      titles = []
      element_set.each do |el|
        titles << el.css('h2').text
      end
      expect(titles).to eq([ 'Title 1', 'Title 2' ])
    end
  end

  describe 'chaining operations' do
    it 'allows complex chaining' do
      # Find all articles, then all links, get their hrefs
      container = described_class.new(doc.css('#container'))
      links = container.find_all('.article')
                       .find_all('a')

      expect(links.count).to eq(2)
      expect(links.pluck_attr('href')).to eq([ '/link1', '/link2' ])
    end

    it 'chains find_by_id -> find_all -> pluck_attr' do
      container = described_class.new(doc.css('#container'))
      urls = container.find_by_id('article1')
                      .find_all('a')
                      .pluck_attr('href')

      expect(urls).to eq([ '/link1' ])
    end
  end
end
