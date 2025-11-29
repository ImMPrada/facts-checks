class CreateVeredicts < ActiveRecord::Migration[8.1]
  def change
    create_table :veredicts do |t|
      t.string :name

      t.timestamps
    end
    add_index :veredicts, :name, unique: true
  end
end
