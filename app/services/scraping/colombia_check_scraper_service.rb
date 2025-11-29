module Scraping
  class ColombiaCheckScraperService
    BASE_URL = "https://colombiacheck.com"
    CHEQUEOS_PATH = "/chequeos"
    SOURCE = :colombia_check

    def get_list_of_fact_urls(page_number)
      url = build_chequeos_url(page_number)
      document = Scraping::Document.fetch(url)

      article_links = document.find_by_id("bloqueImagenes")
                              .find_all(".Chequeo")
                              .find_all("a")
      if article_links.empty?
        raise Scraping::NoArticlesFoundError, "No articles found on page #{page_number}"
      end

      article_links
    end

    def create_fact_urls(article_links)
      urls = article_links.pluck_attr("href")
      created_records = []

      urls.each do |url|
        fact_check_url = FactCheckUrl.create!(url: url, source: SOURCE)
        created_records << fact_check_url
      end

      created_records
    end

    private

    def build_chequeos_url(page_number)
      "#{BASE_URL}#{CHEQUEOS_PATH}?page=#{page_number}"
    end
  end
end
