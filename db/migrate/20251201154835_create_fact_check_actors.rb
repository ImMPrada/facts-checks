class CreateFactCheckActors < ActiveRecord::Migration[8.1]
  def change
    create_table :fact_check_actors do |t|
      t.references :fact_check, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: true
      t.references :actor_role, null: false, foreign_key: true

      t.timestamps
    end
    add_index :fact_check_actors, [ :fact_check_id, :actor_id, :actor_role_id ], unique: true, name: 'index_fact_check_actors_on_fact_check_actor_role'
  end
end
