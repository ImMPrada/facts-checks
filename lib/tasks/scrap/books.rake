namespace :scrap do
  desc "Scrap books from the website"
  task books: :environment do
    puts "Scraping books from the website"

    scraping_service = BooksStore::ScrapService.new("https://books.toscrape.com")
    books_data = scraping_service.run

    initial_categories_count = Category.count
    initial_books_count = Book.count

    books_data.each do |book_data|
      puts "Creating book #{book_data[:title]}"
      category = Categories::UpsertService.new(category_details: book_data[:category]).run
      Books::UpsertService.new(book_details: book_data, category: category).run
    end

    puts "Terminated"
    puts "errors: #{scraping_service.errors}"
    puts "categories count: #{Category.count - initial_categories_count}"
    puts "books count: #{Book.count - initial_books_count}"
  end
end
