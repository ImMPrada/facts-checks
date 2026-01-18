class CreateDisseminators < ActiveRecord::Migration[8.1]
  def change
    create_table :disseminators do |t|
      t.string :name
      t.references :platform, null: false, foreign_key: true

      t.timestamps
    end
  end
end
