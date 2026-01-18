# MineFactCheckUrlJob
#
# Processes undigested FactCheckUrl records by scraping full article content
# and creating FactCheck records with associated data.
#
# WORKFLOW:
#   1. Fetches first undigested FactCheckUrl
#   2. Scrapes article content (title, verdict, reasoning, publication date)
#   3. Creates FactCheck record with Veredict and PublicationDate
#   4. Marks FactCheckUrl as digested
#   5. Self-re-enqueues with 10-20 second delay
#   6. If no URLs found: re-enqueues in 1 week
#
# TRIGGER:
#   - Manually via: `rails scraping:mine_fact_check_urls`
#   - Automatically: self-re-enqueues after each URL processed
#
# ERROR HANDLING:
#   - On failure: marks URL as failed, increments attempts counter
#   - Stores error message in FactCheckUrl.last_error
#   - Continues to next URL (re-enqueues immediately)
#
# DEPENDENCIES:
#   - Scraping::ColombiaCheckScraperService
#   - FactCheck::CreationService
#   - FactCheckUrl, FactCheck, Veredict, PublicationDate models
class MineFactCheckUrlJob < ApplicationJob
  queue_as :default

  def perform
    fact_check_url = FactCheckUrl.undigested.first

    if fact_check_url.nil?
      # No undigested URLs found, re-enqueue for 1 week later
      Rails.logger.info("MineFactCheckUrlJob: No undigested URLs found. Re-enqueueing in 1 week.")
      MineFactCheckUrlJob.set(wait: 1.week).perform_later
      return
    end

    # Scrape the URL using full_url method
    scraper = Scraping::ColombiaCheckScraperService.new
    fact_data = scraper.mine_fact(fact_check_url.full_url)

    # Create the FactCheck record using the service
    creation_service = FactCheck::CreationService.new(fact_data)
    creation_service.build
    fact_check = creation_service.save!

    Rails.logger.info("MineFactCheckUrlJob: Successfully created FactCheck ##{fact_check.id} from #{fact_check_url.full_url}")

    # Mark as digested
    fact_check_url.mark_as_digested!

    # Re-enqueue with random delay of 10-20 seconds
    delay = rand(10..20).seconds
    MineFactCheckUrlJob.set(wait: delay).perform_later
  rescue StandardError => e
    # Mark as failed and re-enqueue immediately to try the next URL
    if fact_check_url
      fact_check_url.mark_as_failed!(e.message)
      Rails.logger.error("MineFactCheckUrlJob: Failed to process #{fact_check_url.full_url}: #{e.message}")
    else
      Rails.logger.error("MineFactCheckUrlJob: Unexpected error: #{e.message}")
    end

    # Re-enqueue with random delay to continue processing
    delay = rand(10..20).seconds
    MineFactCheckUrlJob.set(wait: delay).perform_later
  end
end
