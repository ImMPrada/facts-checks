namespace :scraping do
  desc "Enqueue MineFactCheckUrlJob to start mining undigested fact check URLs"
  task mine_fact_check_urls: :environment do
    MineFactCheckUrlJob.perform_later
    puts "MineFactCheckUrlJob enqueued successfully!"
  end
end
