class AddConfidenceToFactCheckTopics < ActiveRecord::Migration[8.1]
  def change
    add_column :fact_check_topics, :confidence, :float, default: 1.0
  end
end
