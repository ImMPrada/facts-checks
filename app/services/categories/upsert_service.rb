module Categories
  class UpsertService
    def initialize(category_details:)
      @category_details = category_details
    end

    def run
      upsert_category
    end

    private

    attr_reader :category_details

    def upsert_category
      Category.find_or_create_by(
        name: category_details[:name].downcase,
        url: category_details[:url]
      )
    end
  end
end
