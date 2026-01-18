class CreateFactCheckDisseminators < ActiveRecord::Migration[8.1]
  def change
    create_table :fact_check_disseminators do |t|
      t.references :fact_check, null: false, foreign_key: true
      t.references :disseminator, null: false, foreign_key: true

      t.timestamps
    end
    add_index :fact_check_disseminators, [ :fact_check_id, :disseminator_id ], unique: true
  end
end
