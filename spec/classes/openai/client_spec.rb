require "rails_helper"

RSpec.describe Openai::Client do
  let(:api_key) { "test_api_key" }
  let(:client) { described_class.new(api_key: api_key) }

  describe "#initialize" do
    it "creates a client with the provided API key" do
      expect(client.client).to be_a(OpenAI::Client)
    end

    it "uses gpt-4o-mini as default model" do
      expect(client.model).to eq("gpt-4o-mini")
    end

    it "allows custom model selection" do
      custom_client = described_class.new(api_key: api_key, model: "gpt-4")
      expect(custom_client.model).to eq("gpt-4")
    end

    it "uses OPENAI_API_KEY from environment when api_key not provided" do
      allow(ENV).to receive(:fetch).with("OPENAI_API_KEY").and_return("env_key")
      client = described_class.new
      expect(client.client).to be_a(OpenAI::Client)
    end
  end

  describe "#chat" do
    let(:messages) do
      [
        { role: "user", content: "Hello!" }
      ]
    end

    let(:mock_response) do
      {
        "choices" => [
          {
            "message" => {
              "content" => "Hi there!"
            }
          }
        ]
      }
    end

    before do
      allow(client.client).to receive(:chat).and_return(mock_response)
    end

    it "makes a chat request with the provided messages" do
      expect(client.client).to receive(:chat).with(
        parameters: {
          model: "gpt-4o-mini",
          messages: messages,
          temperature: 0.7,
          max_tokens: 500
        }
      )

      client.chat(messages: messages)
    end

    it "returns the content from the response" do
      result = client.chat(messages: messages)
      expect(result).to eq("Hi there!")
    end

    it "strips whitespace from the response" do
      mock_response["choices"][0]["message"]["content"] = "  Hello  "
      result = client.chat(messages: messages)
      expect(result).to eq("Hello")
    end

    it "accepts custom temperature" do
      expect(client.client).to receive(:chat).with(
        parameters: hash_including(temperature: 0.5)
      )

      client.chat(messages: messages, temperature: 0.5)
    end

    it "accepts custom max_tokens" do
      expect(client.client).to receive(:chat).with(
        parameters: hash_including(max_tokens: 1000)
      )

      client.chat(messages: messages, max_tokens: 1000)
    end

    context "when the API request fails" do
      before do
        allow(client.client).to receive(:chat).and_raise(StandardError.new("API error"))
      end

      it "logs the error" do
        allow(Rails.logger).to receive(:error)
        expect(Rails.logger).to receive(:error).with(/OpenAI API error/)

        expect { client.chat(messages: messages) }.to raise_error(Openai::Errors::ClientError)
      end

      it "raises a custom error" do
        expect { client.chat(messages: messages) }
          .to raise_error(Openai::Errors::ClientError, /Failed to get response from OpenAI/)
      end
    end
  end
end
