class CreateActorRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :actor_roles do |t|
      t.string :name

      t.timestamps
    end
    add_index :actor_roles, :name, unique: true
  end
end
