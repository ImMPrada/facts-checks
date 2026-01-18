# ExtractEntitiesJob
#
# Uses OpenAI to extract structured entities (topics, actors, disseminators)
# from FactCheck records and creates associations with related models.
#
# WORKFLOW:
#   1. Fetches first FactCheck with ai_enriched = false
#   2. Calls Ai::ExtractEntitiesService to extract entities via OpenAI
#   3. Calls FactCheck::AssociateEntitiesService to create associations
#   4. Self-re-enqueues immediately to process next FactCheck
#   5. If no FactChecks found: re-enqueues in 1 week
#
# TRIGGER:
#   - Manually via: `rails ai:extract_entities`
#   - Automatically: self-re-enqueues after each FactCheck processed
#
# RETRY MECHANISM:
#   - Retries 3 times on failure
#   - 5 minute wait between retries
#   - Logs errors and re-raises for retry system
#
# ERROR HANDLING:
#   - Ai::Errors::ParseError: invalid JSON response from OpenAI
#   - Openai::Errors::ClientError: OpenAI API failure
#   - ActiveRecord errors: database issues during association creation
#
# ENVIRONMENT:
#   - Requires OPENAI_API_KEY environment variable
#
# COST:
#   - Approximately $0.0008 per FactCheck (using gpt-4o-mini)
#
# DEPENDENCIES:
#   - Ai::ExtractEntitiesService
#   - FactCheck::AssociateEntitiesService
#   - Openai::Client
#   - FactCheck, Topic, Actor, Disseminator models and associations
class ExtractEntitiesJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 5.minutes, attempts: 3

  def perform
    fact_check = ::FactCheck.where(ai_enriched: false).first

    if fact_check
      process_fact_check(fact_check)
      # Re-enqueue immediately to process the next one
      ExtractEntitiesJob.perform_later
    else
      # No more fact checks to process, check again in a week
      ExtractEntitiesJob.set(wait: 1.week).perform_later
    end
  end

  private

  def process_fact_check(fact_check)
    Rails.logger.info(
      "Extracting entities for FactCheck##{fact_check.id}: '#{fact_check.title&.truncate(50)}'"
    )

    # Extract entities using OpenAI
    entities = Ai::ExtractEntitiesService.new(fact_check).call

    Rails.logger.info(
      "Extracted #{entities['topics']&.count || 0} topics, " \
      "#{entities['actors']&.count || 0} actors, " \
      "#{entities['disseminators']&.count || 0} disseminators"
    )

    # Associate entities with the fact check
    ::FactCheck::AssociateEntitiesService.new(fact_check, entities).call

    Rails.logger.info(
      "Successfully enriched FactCheck##{fact_check.id}"
    )
  rescue Ai::Errors::ParseError, Openai::Errors::ClientError => e
    Rails.logger.error(
      "Failed to extract entities for FactCheck##{fact_check.id}: #{e.message}"
    )
    # Let the job retry mechanism handle this
    raise
  end
end
