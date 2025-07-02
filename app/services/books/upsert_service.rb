module Books
  class UpsertService
    def initialize(book_details:, category:)
      @book_details = book_details
      @category = category
    end

    def run
      upsert_book
    end

    private

    attr_reader :book_details, :category

    def upsert_book
      Book.find_or_create_by(
        title: book_details[:title].downcase,
        price: book_details[:price],
        rating: book_details[:rating],
        category:
      )
    end
  end
end
