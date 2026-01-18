class CreateFactChecks < ActiveRecord::Migration[8.1]
  def change
    create_table :fact_checks do |t|
      t.string :source_url
      t.string :title
      t.references :veredict, null: false, foreign_key: true
      t.text :reasoning
      t.references :publication_date, null: true, foreign_key: true
      t.boolean :digested, default: false

      t.timestamps
    end
  end
end
