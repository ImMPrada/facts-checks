module Scraping
  class ElementSet
    include Enumerable

    attr_reader :elements

    def initialize(elements)
      @elements = elements.is_a?(Array) ? elements : [ elements ]
    end

    # Enumerable support
    def each(&block)
      elements.each(&block)
    end

    # Find element by ID within current element set
    # Returns ElementSet or nil
    def find_by_id(element_id)
      result = elements.flat_map do |element|
        element.css("##{element_id}").to_a
      end.compact

      return nil if result.empty?

      ElementSet.new(result)
    end

    # Find all elements matching CSS selector within current element set
    # Returns ElementSet
    def find_all(selector)
      result = elements.flat_map do |element|
        element.css(selector).to_a
      end

      ElementSet.new(result)
    end

    # Find first element matching CSS selector within current element set
    # Returns ElementSet or nil
    def find(selector)
      result = elements.lazy.map do |element|
        element.at_css(selector)
      end.find(&:itself)

      return nil unless result

      ElementSet.new([ result ])
    end

    # Find all elements with specific HTML tag
    # Returns ElementSet
    def find_by_tag(tag_name)
      find_all(tag_name)
    end

    # Get text content of first element
    def text
      first&.text&.strip
    end

    # Get all text from all elements
    def all_text
      elements.map { |el| el.text.strip }.join(" ")
    end

    # Get inner HTML of first element
    def inner_html
      first&.inner_html
    end

    # Get attribute value from first element
    def attr(attribute_name)
      first&.[](attribute_name)
    end

    # Get all attribute values from all elements
    def pluck_attr(attribute_name)
      elements.map { |el| el[attribute_name] }.compact
    end

    # Check if element set is empty
    def empty?
      elements.empty?
    end

    # Check if element set has elements
    def present?
      !empty?
    end

    # Get first element
    def first
      elements.first
    end

    # Get last element
    def last
      elements.last
    end

    # Count elements
    def count
      elements.count
    end

    alias_method :size, :count
    alias_method :length, :count

    # Map over elements
    def map(&block)
      elements.map(&block)
    end

    # Select elements
    def select(&block)
      ElementSet.new(elements.select(&block))
    end

    # Reject elements
    def reject(&block)
      ElementSet.new(elements.reject(&block))
    end
  end
end
