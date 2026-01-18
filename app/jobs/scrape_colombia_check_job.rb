# ScrapeColombiaCheckJob
#
# Scrapes article listing pages from ColombiaCheck.com to discover fact-check URLs.
#
# WORKFLOW:
#   1. Fetches article links from the specified page number
#   2. Creates FactCheckUrl records for each discovered article
#   3. Self-re-enqueues for the next page (10-20 second delay)
#   4. On error or completion: re-enqueues in 1 week starting from page 0
#
# TRIGGER:
#   - Manually via: `rails scraping:enqueue_colombia_check_fact_urls_list`
#   - Automatically: self-re-enqueues after each page
#
# ERROR HANDLING:
#   - ActiveRecord::RecordInvalid: duplicate URL detected (pagination complete)
#   - NoArticlesFoundError: no more articles found (end of results)
#   Both errors trigger a 1-week delay before restarting from page 0
#
# DEPENDENCIES:
#   - Scraping::ColombiaCheckScraperService
#   - FactCheckUrl model
class ScrapeColombiaCheckJob < ApplicationJob
  queue_as :default

  def perform(page_number = 0)
    scraper = Scraping::ColombiaCheckScraperService.new

    article_links = scraper.get_list_of_fact_urls(page_number)
    scraper.create_fact_urls(article_links)

    # Re-enqueue for next page with random delay of 1-3 minutes
    delay = rand(10..20).seconds
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
