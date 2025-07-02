json.array! @books do |book|
  json.id book.id
  json.title book.title
  json.price book.price
  json.rating book.rating
  json.category_name book.category.name
end
