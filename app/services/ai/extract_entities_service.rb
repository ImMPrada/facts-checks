module Ai
  class ExtractEntitiesService
    attr_reader :fact_check, :openai_client

    def initialize(fact_check, openai_client: nil)
      @fact_check = fact_check
      @openai_client = openai_client || Openai::Client.new
    end

    def call
      response = fetch_ai_response
      parse_response(response)
    end

    private

    attr_writer :fact_check, :openai_client

    def fetch_ai_response
      openai_client.chat(
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: user_prompt }
        ],
        temperature: 0.3,
        max_tokens: 2000
      )
    end

    def system_prompt
      <<~PROMPT
        You are an expert at analyzing fact-check articles and extracting structured information.
        You must respond with valid JSON only. Do not include any explanatory text outside the JSON.

        Extract the following entities from fact-check articles:

        1. **Topics**: 2-5 main topics/themes (e.g., "Health", "Politics", "COVID-19")
           - Include a confidence score (0.0 to 1.0) for each topic
           - IMPORTANT: Try to match existing topics when possible: #{existing_topics_sample}

        2. **Actors**: People, organizations, or entities mentioned
           - name: The actor's name (try to match existing actors: #{existing_actors_sample})
           - type: MUST be one of: #{existing_actor_types.inspect}
           - role: MUST be one of: #{existing_actor_roles.inspect}
           - title: Their official title or position (if applicable)
           - description: Brief context about their involvement (1 sentence)

        3. **Disseminators**: Accounts/profiles that spread the claim
           - platform: MUST be one of the common platforms: #{existing_platforms.inspect}
           - name: Account name or handle
           - urls: Array of URLs associated with the disseminator (if mentioned)

        **IMPORTANT MATCHING RULES**:
        - For actors, if you see "President Petro" and "Gustavo Petro" exists, use "Gustavo Petro"
        - For topics, prefer existing topic names when semantically equivalent
        - For platforms, standardize names (e.g., "FB" → "Facebook", "X" → "Twitter")
        - Use exact actor type and role names from the provided lists
        - Match to existing entities when the meaning is the same, even if wording differs

        Respond with this exact JSON structure:
        {
          "topics": [
            {"name": "Topic Name", "confidence": 0.95}
          ],
          "actors": [
            {
              "name": "Actor Name",
              "type": "person",
              "role": "target",
              "title": "Official Title",
              "description": "Brief context about their involvement"
            }
          ],
          "disseminators": [
            {
              "platform": "Facebook",
              "name": "Account Name",
              "urls": ["https://example.com/post"]
            }
          ]
        }

        If no entities of a type are found, return an empty array for that type.
        Be thorough but accurate. Only extract entities that are clearly present in the article.
      PROMPT
    end

    def user_prompt
      <<~PROMPT
        Analyze this fact-check article and extract all topics, actors, and disseminators:

        Title: #{fact_check.title}

        Verdict: #{fact_check.veredict&.name}

        Reasoning: #{fact_check.reasoning}

        Please respond with the extracted entities in the exact JSON format specified.
      PROMPT
    end

    # Provide existing topics as examples (top 30 most common)
    def existing_topics_sample
      @existing_topics_sample ||= begin
        topics = Topic.select(:name)
                      .joins(:fact_check_topics)
                      .group("topics.name")
                      .order("COUNT(fact_check_topics.id) DESC")
                      .limit(30)
                      .pluck(:name)

        topics.any? ? topics.join(", ") : "No existing topics yet"
      end
    end

    # Provide existing actors as examples (top 50 most common)
    def existing_actors_sample
      @existing_actors_sample ||= begin
        actors = Actor.select(:name)
                      .joins(:fact_check_actors)
                      .group("actors.name")
                      .order("COUNT(fact_check_actors.id) DESC")
                      .limit(50)
                      .pluck(:name)

        actors.any? ? actors.join(", ") : "No existing actors yet"
      end
    end

    # Provide all existing actor types (small fixed list)
    def existing_actor_types
      @existing_actor_types ||= begin
        types = ActorType.pluck(:name)
        types.any? ? types : [ "person", "government_entity", "organization" ]
      end
    end

    # Provide all existing actor roles (small fixed list)
    def existing_actor_roles
      @existing_actor_roles ||= begin
        roles = ActorRole.pluck(:name)
        roles.any? ? roles : [ "target", "mentioned", "beneficiary", "source" ]
      end
    end

    # Provide all existing platforms (small fixed list)
    def existing_platforms
      @existing_platforms ||= begin
        platforms = Platform.pluck(:name)
        platforms.any? ? platforms : [ "Facebook", "Twitter", "Instagram", "WhatsApp", "YouTube", "TikTok", "Telegram" ]
      end
    end

    def parse_response(response)
      return default_structure if response.nil? || response.strip.empty?

      # Remove markdown code blocks if present
      cleaned_response = response.gsub(/```json\n?/, "").gsub(/```\n?/, "").strip

      parsed = JSON.parse(cleaned_response)
      validate_structure(parsed)
      parsed
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse AI response: #{e.message}")
      Rails.logger.error("Response was: #{response}")
      raise Errors::ParseError, "Invalid JSON response from AI: #{e.message}"
    end

    def validate_structure(parsed)
      required_keys = %w[topics actors disseminators]
      missing_keys = required_keys - parsed.keys

      if missing_keys.any?
        raise Errors::ParseError, "Missing required keys: #{missing_keys.join(', ')}"
      end

      validate_topics(parsed["topics"])
      validate_actors(parsed["actors"])
      validate_disseminators(parsed["disseminators"])
    end

    def validate_topics(topics)
      return if topics.is_a?(Array)

      raise Errors::ParseError, "Topics must be an array"
    end

    def validate_actors(actors)
      return if actors.is_a?(Array)

      raise Errors::ParseError, "Actors must be an array"
    end

    def validate_disseminators(disseminators)
      return if disseminators.is_a?(Array)

      raise Errors::ParseError, "Disseminators must be an array"
    end

    def default_structure
      {
        "topics" => [],
        "actors" => [],
        "disseminators" => []
      }
    end
  end
end
