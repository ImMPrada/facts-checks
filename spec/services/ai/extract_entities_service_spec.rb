require "rails_helper"

RSpec.describe Ai::ExtractEntitiesService do
  let(:veredict) { create(:veredict, name: "FALSO") }
  let(:fact_check) do
    create(
      :fact_check,
      title: "Claim about vaccines causing autism",
      reasoning: "Multiple scientific studies have debunked this claim. The WHO confirms vaccines are safe.",
      veredict: veredict
    )
  end
  let(:openai_client) { instance_double(Openai::Client) }
  let(:service) { described_class.new(fact_check, openai_client: openai_client) }

  describe "#call" do
    context "when OpenAI returns valid JSON" do
      let(:ai_response) do
        {
          "topics" => [
            { "name" => "Health", "confidence" => 0.95 },
            { "name" => "Vaccines", "confidence" => 0.90 }
          ],
          "actors" => [
            {
              "name" => "World Health Organization",
              "type" => "organization",
              "role" => "source",
              "title" => "UN Health Agency",
              "description" => "Provided scientific evidence against the claim"
            }
          ],
          "disseminators" => [
            {
              "platform" => "Facebook",
              "name" => "Anti-Vax Group",
              "urls" => [ "https://facebook.com/antivax" ]
            }
          ]
        }.to_json
      end

      before do
        allow(openai_client).to receive(:chat).and_return(ai_response)
      end

      it "extracts and parses entities correctly" do
        result = service.call

        expect(result["topics"]).to be_an(Array)
        expect(result["topics"].length).to eq(2)
        expect(result["topics"].first["name"]).to eq("Health")
        expect(result["topics"].first["confidence"]).to eq(0.95)

        expect(result["actors"]).to be_an(Array)
        expect(result["actors"].length).to eq(1)
        expect(result["actors"].first["name"]).to eq("World Health Organization")
        expect(result["actors"].first["type"]).to eq("organization")

        expect(result["disseminators"]).to be_an(Array)
        expect(result["disseminators"].length).to eq(1)
        expect(result["disseminators"].first["platform"]).to eq("Facebook")
      end

      it "calls OpenAI with correct parameters" do
        service.call

        expect(openai_client).to have_received(:chat).with(
          messages: array_including(
            hash_including(role: "system"),
            hash_including(role: "user")
          ),
          temperature: 0.3,
          max_tokens: 2000
        )
      end
    end

    context "when OpenAI returns JSON wrapped in markdown code blocks" do
      let(:ai_response) do
        <<~RESPONSE
          ```json
          {
            "topics": [{"name": "Health", "confidence": 0.95}],
            "actors": [],
            "disseminators": []
          }
          ```
        RESPONSE
      end

      before do
        allow(openai_client).to receive(:chat).and_return(ai_response)
      end

      it "removes markdown formatting and parses correctly" do
        result = service.call

        expect(result["topics"]).to be_an(Array)
        expect(result["topics"].length).to eq(1)
        expect(result["topics"].first["name"]).to eq("Health")
      end
    end

    context "when OpenAI returns empty response" do
      before do
        allow(openai_client).to receive(:chat).and_return("")
      end

      it "returns default structure with empty arrays" do
        result = service.call

        expect(result).to eq(
          "topics" => [],
          "actors" => [],
          "disseminators" => []
        )
      end
    end

    context "when OpenAI returns nil" do
      before do
        allow(openai_client).to receive(:chat).and_return(nil)
      end

      it "returns default structure with empty arrays" do
        result = service.call

        expect(result).to eq(
          "topics" => [],
          "actors" => [],
          "disseminators" => []
        )
      end
    end

    context "when OpenAI returns invalid JSON" do
      before do
        allow(openai_client).to receive(:chat).and_return("not valid json{")
      end

      it "raises a ParseError" do
        expect { service.call }.to raise_error(
          Ai::Errors::ParseError,
          /Invalid JSON response from AI/
        )
      end
    end

    context "when JSON is missing required keys" do
      let(:incomplete_response) do
        {
          "topics" => []
          # Missing actors and disseminators
        }.to_json
      end

      before do
        allow(openai_client).to receive(:chat).and_return(incomplete_response)
      end

      it "raises a ParseError" do
        expect { service.call }.to raise_error(
          Ai::Errors::ParseError,
          /Missing required keys: actors, disseminators/
        )
      end
    end

    context "when topics is not an array" do
      let(:invalid_response) do
        {
          "topics" => "not an array",
          "actors" => [],
          "disseminators" => []
        }.to_json
      end

      before do
        allow(openai_client).to receive(:chat).and_return(invalid_response)
      end

      it "raises a ParseError" do
        expect { service.call }.to raise_error(
          Ai::Errors::ParseError,
          /Topics must be an array/
        )
      end
    end

    context "when actors is not an array" do
      let(:invalid_response) do
        {
          "topics" => [],
          "actors" => "not an array",
          "disseminators" => []
        }.to_json
      end

      before do
        allow(openai_client).to receive(:chat).and_return(invalid_response)
      end

      it "raises a ParseError" do
        expect { service.call }.to raise_error(
          Ai::Errors::ParseError,
          /Actors must be an array/
        )
      end
    end

    context "when disseminators is not an array" do
      let(:invalid_response) do
        {
          "topics" => [],
          "actors" => [],
          "disseminators" => "not an array"
        }.to_json
      end

      before do
        allow(openai_client).to receive(:chat).and_return(invalid_response)
      end

      it "raises a ParseError" do
        expect { service.call }.to raise_error(
          Ai::Errors::ParseError,
          /Disseminators must be an array/
        )
      end
    end

    context "when OpenAI client raises an error" do
      before do
        allow(openai_client).to receive(:chat).and_raise(
          Openai::Errors::ClientError, "API rate limit exceeded"
        )
      end

      it "propagates the error" do
        expect { service.call }.to raise_error(
          Openai::Errors::ClientError,
          /API rate limit exceeded/
        )
      end
    end
  end
end
