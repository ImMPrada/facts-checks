namespace :scraping do
  desc "Enqueue ScrapeColombiaCheckJob to start scraping ColombiaCheck.com fact URLs"
  task enqueue_colombia_check_fact_urls_list: :environment do
    ScrapeColombiaCheckJob.perform_later
    puts "ScrapeColombiaCheckJob enqueued successfully!"
  end
end
