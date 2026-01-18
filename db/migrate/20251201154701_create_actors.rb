class CreateActors < ActiveRecord::Migration[8.1]
  def change
    create_table :actors do |t|
      t.string :name
      t.references :actor_type, null: false, foreign_key: true

      t.timestamps
    end
    add_index :actors, :name
  end
end
