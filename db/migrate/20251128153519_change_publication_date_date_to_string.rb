class ChangePublicationDateDateToString < ActiveRecord::Migration[8.1]
  def up
    change_column :publication_dates, :date, :string
  end

  def down
    change_column :publication_dates, :date, :date
  end
end
