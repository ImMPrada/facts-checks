module PublicationDates
  class ParseDateService
    attr_reader :publication_date, :openai_client

    def initialize(publication_date, openai_client: nil)
      @publication_date = publication_date
      @openai_client = openai_client || Openai::Client.new
    end

    def call
      return if publication_date.date.blank?

      parsed_date = parse_date_with_openai
      publication_date.update!(value: parsed_date)
      parsed_date
    rescue StandardError => e
      Rails.logger.error(
        "Failed to parse date for PublicationDate##{publication_date.id}: #{e.message}"
      )
      raise Errors::ParseDateServiceError, "Failed to parse date: #{e.message}"
    end

    private

    def parse_date_with_openai
      messages = [
        {
          role: "system",
          content: system_prompt
        },
        {
          role: "user",
          content: publication_date.date
        }
      ]

      response = openai_client.chat(messages: messages, temperature: 0.0)
      parse_response(response)
    end

    def system_prompt
      <<~PROMPT
        You are a date parsing assistant. Parse date strings and return them in YYYY-MM-DD format.

        Instructions:
        - Parse dates in any format (Spanish or English)
        - Accept dates with or without time information
        - If there's NO time: just return the date as YYYY-MM-DD
        - If there's time: assume Colombia/Bogota timezone (UTC-5), add 5 hours to convert to UTC, adjust the date if it crosses midnight
        - Return ONLY the date in YYYY-MM-DD format, nothing else
        - If you cannot parse the date, respond with "INVALID"

        Examples:
        "Jueves, 27 Noviembre 2025" → "2025-11-27"
        "2024-01-15" → "2024-01-15"
        "2024-01-15 20:00:00" → "2024-01-16" (20:00 + 5hrs = 01:00 next day)
        "2024-01-15 10:00:00" → "2024-01-15" (10:00 + 5hrs = 15:00 same day)
      PROMPT
    end

    def parse_response(response)
      if response.nil? || response == "INVALID"
        raise Errors::ParseDateServiceError, "OpenAI could not parse the date: #{publication_date.date}"
      end

      date = Date.parse(response)
      validate_date(date)
      date
    rescue ArgumentError => e
      raise Errors::ParseDateServiceError, "Invalid date format from OpenAI: #{response}"
    end

    def validate_date(date)
      if date.year < 1900 || date.year > 2100
        raise Errors::ParseDateServiceError, "Date year out of reasonable range: #{date}"
      end
    end
  end
end
