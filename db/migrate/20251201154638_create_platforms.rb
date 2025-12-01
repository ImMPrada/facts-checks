class CreatePlatforms < ActiveRecord::Migration[8.1]
  def change
    create_table :platforms do |t|
      t.string :name

      t.timestamps
    end
    add_index :platforms, :name, unique: true
  end
end
