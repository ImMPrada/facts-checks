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
