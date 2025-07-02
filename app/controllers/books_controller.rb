class BooksController < ApplicationController
  def index
    @books = Book.includes(:category).all
  end
end
