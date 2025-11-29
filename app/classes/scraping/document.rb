module Scraping
  class Document
    attr_reader :nokogiri_doc, :url

    # Fetch HTML from URL and return Document instance
    def self.fetch(url, options = {})
      response = HTTParty.get(url, options)
      raise "HTTP Error: #{response.code}" unless response.success?

      new(response.body, url)
    end

    def initialize(html_content, url = nil)
      @nokogiri_doc = Nokogiri::HTML(html_content)
      @url = url
    end

    # Find single element by ID
    # Returns ElementSet or nil
    def find_by_id(element_id)
      element = nokogiri_doc.at_css("##{element_id}")
      return nil unless element

      ElementSet.new([ element ])
    end

    # Find all elements matching CSS selector
    # Returns ElementSet
    def find_all(selector)
      elements = nokogiri_doc.css(selector).to_a
      ElementSet.new(elements)
    end

    # Find first element matching CSS selector
    # Returns ElementSet or nil
    def find(selector)
      element = nokogiri_doc.at_css(selector)
      return nil unless element

      ElementSet.new([ element ])
    end

    # Get page title
    def title
      nokogiri_doc.title
    end

    # Get all text content
    def text
      nokogiri_doc.text
    end
  end
end
