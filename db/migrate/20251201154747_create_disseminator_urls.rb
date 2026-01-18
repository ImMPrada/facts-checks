class CreateDisseminatorUrls < ActiveRecord::Migration[8.1]
  def change
    create_table :disseminator_urls do |t|
      t.references :disseminator, null: false, foreign_key: true
      t.string :url

      t.timestamps
    end
  end
end
