class CreateBooks < ActiveRecord::Migration[8.0]
  def change
    create_table :books do |t|
      t.string :title, null: false
      t.decimal :price
      t.integer :rating
      

      t.timestamps
    end
  end
end
