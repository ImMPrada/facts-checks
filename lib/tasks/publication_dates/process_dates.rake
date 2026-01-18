namespace :publication_dates do
  desc "Process publication dates using OpenAI to parse date values"
  task process_dates: :environment do
    puts "Enqueuing ProcessPublicationDatesJob..."
    ProcessPublicationDatesJob.perform_later
    puts "Job enqueued successfully!"
    puts "The job will process all PublicationDates with nil value."
    puts "Run 'bin/delayed_job start' to process jobs in the background."
  end
end
