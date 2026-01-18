class AddAiEnrichmentToFactChecks < ActiveRecord::Migration[8.1]
  def change
    add_column :fact_checks, :ai_enriched, :boolean, default: false
    add_column :fact_checks, :ai_enriched_at, :datetime
    add_index :fact_checks, :ai_enriched
  end
end
