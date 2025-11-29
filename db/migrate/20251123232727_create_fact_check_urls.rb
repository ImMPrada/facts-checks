class CreateFactCheckUrls < ActiveRecord::Migration[8.1]
  def change
    create_table :fact_check_urls do |t|
      t.string :url, null: false
      t.boolean :digested, default: false, null: false
      t.integer :source, null: false
      t.datetime :digested_at
      t.integer :attempts, default: 0, null: false
      t.text :last_error

      t.timestamps
    end

    add_index :fact_check_urls, :url, unique: true
    add_index :fact_check_urls, :digested
    add_index :fact_check_urls, [ :source, :digested ]
  end
end
