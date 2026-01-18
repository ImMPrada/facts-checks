class AddMetadataToFactCheckActors < ActiveRecord::Migration[8.1]
  def change
    add_column :fact_check_actors, :title, :string
    add_column :fact_check_actors, :description, :text
  end
end
