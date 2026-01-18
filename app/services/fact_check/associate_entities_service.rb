class FactCheck::AssociateEntitiesService
  attr_reader :fact_check, :entities

  def initialize(fact_check, entities)
    self.fact_check = fact_check
    self.entities = entities
  end

  def call
    ActiveRecord::Base.transaction do
      clear_existing_associations
      associate_topics
      associate_actors
      associate_disseminators
      mark_as_enriched
    end

    fact_check
  end

  private

  attr_writer :fact_check, :entities

  def clear_existing_associations
    # Clear existing AI-generated associations to allow re-enrichment
    fact_check.fact_check_topics.destroy_all
    fact_check.fact_check_actors.destroy_all
    fact_check.fact_check_disseminators.destroy_all
  end

  def associate_topics
    return if entities["topics"].blank?

    entities["topics"].each do |topic_data|
      topic = Topic.find_or_create_by!(name: topic_data["name"])

      fact_check.fact_check_topics.create!(
        topic: topic,
        confidence: topic_data["confidence"] || 1.0
      )
    end
  end

  def associate_actors
    return if entities["actors"].blank?

    entities["actors"].each do |actor_data|
      # Find or create ActorType
      actor_type = ActorType.find_or_create_by!(
        name: normalize_actor_type(actor_data["type"])
      )

      # Find or create Actor
      actor = Actor.find_or_create_by!(
        name: actor_data["name"],
        actor_type: actor_type
      )

      # Find or create ActorRole
      actor_role = ActorRole.find_or_create_by!(
        name: normalize_actor_role(actor_data["role"])
      )

      # Create association with metadata
      fact_check.fact_check_actors.create!(
        actor: actor,
        actor_role: actor_role,
        title: actor_data["title"],
        description: actor_data["description"]
      )
    end
  end

  def associate_disseminators
    return if entities["disseminators"].blank?

    entities["disseminators"].each do |disseminator_data|
      # Find or create Platform
      platform = Platform.find_or_create_by!(
        name: normalize_platform(disseminator_data["platform"])
      )

      # Find or create Disseminator
      disseminator = Disseminator.find_or_create_by!(
        name: disseminator_data["name"],
        platform: platform
      )

      # Create DisseminatorUrls if URLs are provided
      if disseminator_data["urls"].present?
        disseminator_data["urls"].each do |url|
          DisseminatorUrl.find_or_create_by!(
            disseminator: disseminator,
            url: url
          )
        end
      end

      # Create association
      fact_check.fact_check_disseminators.create!(disseminator: disseminator)
    end
  end

  def mark_as_enriched
    fact_check.update!(
      ai_enriched: true,
      ai_enriched_at: Time.current
    )
  end

  # Normalize actor type to ensure consistency
  def normalize_actor_type(type)
    return "person" if type.blank?

    normalized = type.to_s.downcase.strip

    case normalized
    when "person", "individual", "people"
      "person"
    when "government", "government_entity", "gov"
      "government_entity"
    when "organization", "org", "company", "institution"
      "organization"
    else
      normalized
    end
  end

  # Normalize actor role to ensure consistency
  def normalize_actor_role(role)
    return "mentioned" if role.blank?

    normalized = role.to_s.downcase.strip

    case normalized
    when "target", "subject"
      "target"
    when "mentioned", "reference", "referenced"
      "mentioned"
    when "beneficiary", "benefit"
      "beneficiary"
    when "source", "author"
      "source"
    else
      normalized
    end
  end

  # Normalize platform name to ensure consistency
  def normalize_platform(platform)
    return "Unknown" if platform.blank?

    normalized = platform.to_s.strip

    # Capitalize first letter of each word
    normalized.split.map(&:capitalize).join(" ")
  end
end
