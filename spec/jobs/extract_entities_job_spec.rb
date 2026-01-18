require "rails_helper"

RSpec.describe ExtractEntitiesJob, type: :job do
  let(:veredict) { create(:veredict) }
  let(:entities_response) do
    {
      "topics" => [ { "name" => "Health", "confidence" => 0.95 } ],
      "actors" => [
        {
          "name" => "Dr. Smith",
          "type" => "person",
          "role" => "source",
          "title" => "Doctor",
          "description" => "Medical expert"
        }
      ],
      "disseminators" => []
    }
  end

  describe "#perform" do
    context "when there are un-enriched fact checks" do
      let!(:fact_check) { create(:fact_check, veredict: veredict, ai_enriched: false) }

      before do
        allow(Ai::ExtractEntitiesService).to receive(:new).and_return(
          instance_double(Ai::ExtractEntitiesService, call: entities_response)
        )
        allow(FactCheck::AssociateEntitiesService).to receive(:new).and_return(
          instance_double(FactCheck::AssociateEntitiesService, call: fact_check)
        )
      end

      it "processes the first un-enriched fact check" do
        described_class.new.perform

        expect(Ai::ExtractEntitiesService).to have_received(:new).with(fact_check)
        expect(FactCheck::AssociateEntitiesService).to have_received(:new).with(
          fact_check, entities_response
        )
      end

      it "re-enqueues itself immediately" do
        expect { described_class.new.perform }.to have_enqueued_job(described_class)
      end
    end

    context "when there are no un-enriched fact checks" do
      it "re-enqueues itself to run in 1 week" do
        expect do
          described_class.new.perform
        end.to have_enqueued_job(described_class).at_least(1).times
      end
    end

    context "when there are multiple un-enriched fact checks" do
      let!(:fact_check1) { create(:fact_check, veredict: veredict, ai_enriched: false) }
      let!(:fact_check2) { create(:fact_check, veredict: veredict, ai_enriched: false) }

      before do
        allow(Ai::ExtractEntitiesService).to receive(:new).and_return(
          instance_double(Ai::ExtractEntitiesService, call: entities_response)
        )
        allow(FactCheck::AssociateEntitiesService).to receive(:new).and_return(
          instance_double(FactCheck::AssociateEntitiesService, call: fact_check1)
        )
      end

      it "processes only the first one" do
        described_class.new.perform

        expect(Ai::ExtractEntitiesService).to have_received(:new).once
      end

      it "re-enqueues itself to process the next one" do
        expect { described_class.new.perform }.to have_enqueued_job(described_class)
      end
    end

    context "when extraction fails with ParseError" do
      let!(:fact_check) { create(:fact_check, veredict: veredict, ai_enriched: false) }
      let(:extract_service) { instance_double(Ai::ExtractEntitiesService) }

      before do
        allow(Ai::ExtractEntitiesService).to receive(:new).and_return(extract_service)
        allow(extract_service).to receive(:call).and_raise(Ai::Errors::ParseError, "Invalid JSON")
      end

      it "raises the error for retry mechanism" do
        expect { described_class.new.perform }.to raise_error(Ai::Errors::ParseError)
      end
    end

    context "when extraction fails with OpenAI ClientError" do
      let!(:fact_check) { create(:fact_check, veredict: veredict, ai_enriched: false) }
      let(:extract_service) { instance_double(Ai::ExtractEntitiesService) }

      before do
        allow(Ai::ExtractEntitiesService).to receive(:new).and_return(extract_service)
        allow(extract_service).to receive(:call).and_raise(Openai::Errors::ClientError, "API error")
      end

      it "raises the error for retry mechanism" do
        expect { described_class.new.perform }.to raise_error(Openai::Errors::ClientError)
      end
    end

    context "when processing an already enriched fact check" do
      let!(:enriched_fact_check) do
        create(:fact_check, veredict: veredict, ai_enriched: true, ai_enriched_at: 1.day.ago)
      end

      it "skips it and re-enqueues for 1 week later" do
        allow(Ai::ExtractEntitiesService).to receive(:new)

        expect do
          described_class.new.perform
        end.to have_enqueued_job(described_class).at_least(1).times

        expect(Ai::ExtractEntitiesService).not_to have_received(:new)
      end
    end

    context "integration test with real services" do
      let!(:fact_check) do
        create(
          :fact_check,
          title: "Test claim",
          reasoning: "Test reasoning",
          veredict: veredict,
          ai_enriched: false
        )
      end
      let(:openai_client) { instance_double(Openai::Client) }

      before do
        allow(Openai::Client).to receive(:new).and_return(openai_client)
        allow(openai_client).to receive(:chat).and_return(entities_response.to_json)
      end

      it "successfully extracts and associates entities" do
        described_class.new.perform

        fact_check.reload
        expect(fact_check.ai_enriched).to be(true)
        expect(fact_check.ai_enriched_at).to be_present
        expect(fact_check.topics.count).to eq(1)
        expect(fact_check.actors.count).to eq(1)
      end
    end
  end
end
