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

    def mine_fact(url)
      document = Scraping::Document.fetch(url)

      {
        source_url: url,
        veredict: extract_veredict(document),
        title: extract_title(document),
        reasoning: extract_reasoning(document),
        publication_date: extract_publication_date(document)
      }
    end

    private

    def build_chequeos_url(page_number)
      "#{BASE_URL}#{CHEQUEOS_PATH}?page=#{page_number}"
    end

    def extract_veredict(document)
      veredict_element = document.find(".Portada-bandera-text")
      return nil if veredict_element.nil?
      veredict_element.text
    end

    def extract_title(document)
      text_articulos = document.find(".text-articulos")
      return nil if text_articulos.nil?

      title_element = text_articulos.find("div").find("h2").find("span")
      return nil if title_element.nil?
      title_element.text
    end

    def extract_reasoning(document)
      text_articulos = document.find(".text-articulos")
      return nil if text_articulos.nil?

      text_articulos_div = text_articulos.find("div")
      return nil if text_articulos_div.nil?

      reasoning_parts = []

      # h3 text
      h3 = text_articulos_div.find("h3")
      reasoning_parts << h3.text unless h3.nil?

      # datos-clave section
      datos_clave = text_articulos_div.find_by_id("datos-claves")
      unless datos_clave.nil?
        # h2 in datos-clave
        datos_h2 = datos_clave.find("h2")
        reasoning_parts << datos_h2.text unless datos_h2.nil?

        # all li in datos-clave ol
        ol = datos_clave.find("ol")
        unless ol.nil?
          lis = ol.find_all("li")
          lis.each do |li_element|
            reasoning_parts << Scraping::ElementSet.new(li_element).text
          end
        end
      end

      # All divs without id - find their p, h, and li tags in HTML order
      all_divs = text_articulos_div.find_all("div")
      all_divs.each do |div_element|
        # Wrap the element in an ElementSet
        div = Scraping::ElementSet.new(div_element)

        # Skip if it has an id attribute
        next if div.attr("id")

        # Get all p, h, and li tags together (maintains HTML order)
        content_elements = div.find_all("p, h1, h2, h3, h4, h5, h6, li")
        content_elements.each do |element|
          element_set = Scraping::ElementSet.new(element)
          text_content = element_set.text

          # Extract links from this element and append them
          links = element_set.find_all("a")
          unless links.empty?
            link_urls = links.pluck_attr("href").compact
            unless link_urls.empty?
              text_content += "\n" + link_urls.map { |url| "Link: #{url}" }.join("\n")
            end
          end

          reasoning_parts << text_content
        end
      end

      reasoning_parts.compact.reject(&:empty?).join("\n\n")
    end

    def extract_publication_date(document)
      text_articulos = document.find(".text-articulos")
      return nil if text_articulos.nil?

      date_element = text_articulos.find("div").find("h5")
      return nil if date_element.nil?

      date_element.text
    end
  end
end
