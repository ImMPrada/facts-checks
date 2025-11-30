class AddValueToPublicationDates < ActiveRecord::Migration[8.1]
  def change
    add_column :publication_dates, :value, :date
    add_index :publication_dates, :value
  end
end
