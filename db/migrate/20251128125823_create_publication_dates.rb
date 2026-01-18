class CreatePublicationDates < ActiveRecord::Migration[8.1]
  def change
    create_table :publication_dates do |t|
      t.date :date

      t.timestamps
    end
    add_index :publication_dates, :date, unique: true
  end
end
