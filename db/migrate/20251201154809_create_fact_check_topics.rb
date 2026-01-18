class CreateFactCheckTopics < ActiveRecord::Migration[8.1]
  def change
    create_table :fact_check_topics do |t|
      t.references :fact_check, null: false, foreign_key: true
      t.references :topic, null: false, foreign_key: true

      t.timestamps
    end
    add_index :fact_check_topics, [ :fact_check_id, :topic_id ], unique: true
  end
end
