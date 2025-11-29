class ScrapeColombiaCheckJob < ApplicationJob
  queue_as :default

  def perform(page_number = 0)
    scraper = Scraping::ColombiaCheckScraperService.new

    article_links = scraper.get_list_of_fact_urls(page_number)
    scraper.create_fact_urls(article_links)

    # Re-enqueue for next page with random delay of 1-3 minutes
    delay = rand(1..3).minutes
    ScrapeColombiaCheckJob.set(wait: delay).perform_later(page_number + 1)
  rescue ActiveRecord::RecordInvalid => e
    # Re-enqueue for 1 week later, starting from page 0
    Rails.logger.info("ScrapeColombiaCheckJob stopped at page #{page_number}: #{e.message}. Re-enqueueing in 1 week.")
    ScrapeColombiaCheckJob.set(wait: 1.week).perform_later
  rescue Scraping::NoArticlesFoundError => e
    # Re-enqueue for 1 week later, starting from page 0
    Rails.logger.info("ScrapeColombiaCheckJob stopped at page #{page_number}: #{e.message}. Re-enqueueing in 1 week.")
    ScrapeColombiaCheckJob.set(wait: 1.week).perform_later
  end
end
