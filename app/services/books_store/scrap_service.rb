require "open-uri"

module BooksStore
  class ScrapService
    RATING_MAP = {
      "One" => 1,
      "Two" => 2,
      "Three" => 3,
      "Four" => 4,
      "Five" => 5
    }

    attr_reader :errors, :page

    # https://books.toscrape.com
    def initialize(base_url)
      @base_url = base_url
      @errors = {}
      @page = 1
    end

    def run
      raise "Total pages arraised" if page > total_pages
      books_details = []

      books_details_links = get_page_links.uniq
      books_details_links.each do |link|
        book_details = get_book_details(link)
        puts book_details
        books_details << book_details
      rescue => e
        errors[link] = e.message
      end

      @page += 1
      books_details
    end

    def total_pages
      return @total_pages if @total_pages

      pages = 0
      doc = Nokogiri::HTML(URI.open("#{base_url}/catalogue/page-1.html"))
      doc.css("ul.pager li.current").each do |element|
        pages = element.text.split("of ").last.to_i
      end

      @total_pages = pages
    end

    private

    attr_reader :base_url

    def get_page_links
      puts "Getting page #{page} links"
      url ="#{base_url}/catalogue/page-#{page}.html"
      doc = Nokogiri::HTML(URI.open(url))
      doc.css("article.product_pod a").map do |element|
        element["href"]
      end
    end

    def get_book_details(link)
      puts "Getting book details for #{link}"
      url = "#{base_url}/catalogue/#{link}"
      doc = Nokogiri::HTML(URI.open(url))

      data = {}

      data[:title] = doc.css("div.product_main h1").text
      data[:price] = doc.css("p.price_color").text.split("£").last.to_f
      data[:rating] = RATING_MAP[doc.css("p.star-rating").attr("class").value.split(" ").last]
      data[:category] = {
        name: doc.css("ul.breadcrumb li a").map(&:text).last,
        url: doc.css("ul.breadcrumb li a").map { |element| element["href"] }.last.gsub("..", base_url)
      }

      data
    end
  end
end
