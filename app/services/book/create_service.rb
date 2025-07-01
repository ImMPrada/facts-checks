module Book
  class CreateService
    def initialize(book_details)
      @book_details = book_details
    end

    def run
      create_book
    end

    private

    attr_reader :book_details

    def category
      Category.find_or_create_by(name: book_details[:category_name].downcase)
    end

    def create_book
      Book.find_or_create_by(
        title: book_details[:title].downcase,
        price: book_details[:price],
        rating: book_details[:rating],
        category:
      )
    end
  end
end
