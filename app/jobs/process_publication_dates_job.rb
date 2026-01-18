# ProcessPublicationDatesJob
#
# Uses OpenAI to parse raw date strings into UTC Date values.
# Converts date strings scraped from ColombiaCheck.com (Colombia/Bogota timezone)
# into standardized UTC dates stored in PublicationDate.value field.
#
# WORKFLOW:
#   1. Fetches first PublicationDate with nil value
#   2. Sends date string to OpenAI for parsing
#   3. Updates PublicationDate.value with parsed UTC date
#   4. Self-re-enqueues immediately to process next date
#   5. If no dates found: re-enqueues in 1 week
#
# TRIGGER:
#   - Manually via: `rails publication_dates:process_dates`
#   - Automatically: self-re-enqueues after each date processed
#
# RETRY MECHANISM:
#   - Retries 3 times on failure
#   - 5 minute wait between retries
#   - Logs errors and re-raises for retry system
#
# ERROR HANDLING:
#   - ParseDateError: invalid date format or out-of-range year
#   - Openai::Errors::ClientError: OpenAI API failure
#
# ENVIRONMENT:
#   - Requires OPENAI_API_KEY environment variable
#
# DEPENDENCIES:
#   - PublicationDates::ParseDateService
#   - Openai::Client
#   - PublicationDate model
class ProcessPublicationDatesJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 5.minutes, attempts: 3

  def perform
    publication_date = PublicationDate.where(value: nil).first

    if publication_date
      process_publication_date(publication_date)
      # Re-enqueue immediately to process the next one
      ProcessPublicationDatesJob.perform_later
    else
      # No more dates to process, check again in a week
      ProcessPublicationDatesJob.set(wait: 1.week).perform_later
    end
  end

  private

  def process_publication_date(publication_date)
    Rails.logger.info(
      "Processing PublicationDate##{publication_date.id} with date: '#{publication_date.date}'"
    )

    PublicationDates::ParseDateService.new(publication_date).call

    Rails.logger.info(
      "Successfully processed PublicationDate##{publication_date.id}, value: #{publication_date.value}"
    )
  rescue ParseDateError => e
    Rails.logger.error(
      "Failed to process PublicationDate##{publication_date.id}: #{e.message}"
    )
    # Let the job retry mechanism handle this
    raise
  end
end
