module Openai
  class Client
    attr_reader :client, :model

    def initialize(api_key: nil, model: "gpt-4o-mini")
      @client = OpenAI::Client.new(
        access_token: api_key || ENV.fetch("OPENAI_API_KEY")
      )
      @model = model
    end

    # Makes a chat completion request to OpenAI
    #
    # @param messages [Array<Hash>] Array of message hashes with :role and :content
    # @param temperature [Float] Sampling temperature (0.0 to 2.0)
    # @param max_tokens [Integer] Maximum tokens in response
    # @return [String] The response content
    # @raise [Openai::Client::Error] If the API request fails
    def chat(messages:, temperature: 0.7, max_tokens: 500)
      response = client.chat(
        parameters: {
          model: model,
          messages: messages,
          temperature: temperature,
          max_tokens: max_tokens
        }
      )

      extract_content(response)
    rescue StandardError => e
      Rails.logger.error("OpenAI API error: #{e.message}")
      raise Errors::ClientError, "Failed to get response from OpenAI: #{e.message}"
    end

    private

    def extract_content(response)
      response.dig("choices", 0, "message", "content")&.strip
    end
  end
end
