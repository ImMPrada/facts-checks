class CreateActorTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :actor_types do |t|
      t.string :name

      t.timestamps
    end
    add_index :actor_types, :name, unique: true
  end
end
