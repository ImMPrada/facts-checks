require "rails_helper"

RSpec.describe FactCheck::AssociateEntitiesService do
  let(:veredict) { create(:veredict) }
  let(:fact_check) { create(:fact_check, veredict: veredict) }

  let(:entities) do
    {
      "topics" => [
        { "name" => "Health", "confidence" => 0.95 },
        { "name" => "Vaccines", "confidence" => 0.90 }
      ],
      "actors" => [
        {
          "name" => "Dr. Jane Smith",
          "type" => "person",
          "role" => "source",
          "title" => "Chief Medical Officer",
          "description" => "Provided expert testimony on vaccine safety"
        },
        {
          "name" => "Ministry of Health",
          "type" => "government_entity",
          "role" => "target",
          "title" => nil,
          "description" => "Subject of the misinformation claim"
        }
      ],
      "disseminators" => [
        {
          "platform" => "Facebook",
          "name" => "Anti-Vax Group",
          "urls" => [ "https://facebook.com/antivax", "https://facebook.com/antivax/post123" ]
        },
        {
          "platform" => "Twitter",
          "name" => "@conspiracy_account",
          "urls" => []
        }
      ]
    }
  end

  let(:service) { described_class.new(fact_check, entities) }

  describe "#call" do
    it "creates topic associations with confidence scores" do
      expect { service.call }.to change { fact_check.topics.count }.by(2)

      health_topic = Topic.find_by(name: "Health")
      vaccines_topic = Topic.find_by(name: "Vaccines")

      expect(health_topic).to be_present
      expect(vaccines_topic).to be_present

      health_association = fact_check.fact_check_topics.find_by(topic: health_topic)
      vaccines_association = fact_check.fact_check_topics.find_by(topic: vaccines_topic)

      expect(health_association.confidence).to eq(0.95)
      expect(vaccines_association.confidence).to eq(0.90)
    end

    it "creates actor associations with metadata" do
      expect { service.call }.to change { fact_check.actors.count }.by(2)

      dr_smith = Actor.find_by(name: "Dr. Jane Smith")
      ministry = Actor.find_by(name: "Ministry of Health")

      expect(dr_smith).to be_present
      expect(ministry).to be_present

      smith_association = fact_check.fact_check_actors.find_by(actor: dr_smith)
      ministry_association = fact_check.fact_check_actors.find_by(actor: ministry)

      expect(smith_association.title).to eq("Chief Medical Officer")
      expect(smith_association.description).to eq("Provided expert testimony on vaccine safety")
      expect(smith_association.actor_role.name).to eq("source")

      expect(ministry_association.title).to be_nil
      expect(ministry_association.description).to eq("Subject of the misinformation claim")
      expect(ministry_association.actor_role.name).to eq("target")
    end

    it "creates actor types correctly" do
      service.call

      dr_smith = Actor.find_by(name: "Dr. Jane Smith")
      ministry = Actor.find_by(name: "Ministry of Health")

      expect(dr_smith.actor_type.name).to eq("person")
      expect(ministry.actor_type.name).to eq("government_entity")
    end

    it "creates disseminator associations with platforms and URLs" do
      expect { service.call }.to change { fact_check.disseminators.count }.by(2)

      facebook_disseminator = Disseminator.find_by(name: "Anti-Vax Group")
      twitter_disseminator = Disseminator.find_by(name: "@conspiracy_account")

      expect(facebook_disseminator).to be_present
      expect(twitter_disseminator).to be_present

      expect(facebook_disseminator.platform.name).to eq("Facebook")
      expect(twitter_disseminator.platform.name).to eq("Twitter")

      expect(facebook_disseminator.disseminator_urls.count).to eq(2)
      expect(facebook_disseminator.disseminator_urls.pluck(:url)).to contain_exactly(
        "https://facebook.com/antivax",
        "https://facebook.com/antivax/post123"
      )

      expect(twitter_disseminator.disseminator_urls.count).to eq(0)
    end

    it "marks the fact check as ai_enriched" do
      Timecop.freeze do
        service.call

        fact_check.reload
        expect(fact_check.ai_enriched).to be(true)
        expect(fact_check.ai_enriched_at).to be_within(1.second).of(Time.current)
      end
    end

    it "clears existing associations before creating new ones" do
      # Create some initial associations
      topic1 = create(:topic, name: "Old Topic")
      fact_check.fact_check_topics.create!(topic: topic1, confidence: 0.5)

      expect(fact_check.topics.count).to eq(1)

      service.call

      fact_check.reload
      expect(fact_check.topics.pluck(:name)).not_to include("Old Topic")
      expect(fact_check.topics.pluck(:name)).to include("Health", "Vaccines")
    end

    it "handles empty topics array" do
      entities["topics"] = []

      expect { service.call }.not_to change { fact_check.topics.count }
    end

    it "handles empty actors array" do
      entities["actors"] = []

      expect { service.call }.not_to change { fact_check.actors.count }
    end

    it "handles empty disseminators array" do
      entities["disseminators"] = []

      expect { service.call }.not_to change { fact_check.disseminators.count }
    end

    it "normalizes actor types correctly" do
      entities["actors"] = [
        { "name" => "Person 1", "type" => "individual", "role" => "mentioned" },
        { "name" => "Person 2", "type" => "PERSON", "role" => "mentioned" },
        { "name" => "Gov 1", "type" => "government", "role" => "mentioned" },
        { "name" => "Org 1", "type" => "company", "role" => "mentioned" }
      ]

      service.call

      expect(Actor.find_by(name: "Person 1").actor_type.name).to eq("person")
      expect(Actor.find_by(name: "Person 2").actor_type.name).to eq("person")
      expect(Actor.find_by(name: "Gov 1").actor_type.name).to eq("government_entity")
      expect(Actor.find_by(name: "Org 1").actor_type.name).to eq("organization")
    end

    it "normalizes actor roles correctly" do
      entities["actors"] = [
        { "name" => "Actor 1", "type" => "person", "role" => "subject" },
        { "name" => "Actor 2", "type" => "person", "role" => "reference" },
        { "name" => "Actor 3", "type" => "person", "role" => "benefit" },
        { "name" => "Actor 4", "type" => "person", "role" => "author" }
      ]

      service.call

      expect(fact_check.fact_check_actors.find_by(actor: Actor.find_by(name: "Actor 1")).actor_role.name).to eq("target")
      expect(fact_check.fact_check_actors.find_by(actor: Actor.find_by(name: "Actor 2")).actor_role.name).to eq("mentioned")
      expect(fact_check.fact_check_actors.find_by(actor: Actor.find_by(name: "Actor 3")).actor_role.name).to eq("beneficiary")
      expect(fact_check.fact_check_actors.find_by(actor: Actor.find_by(name: "Actor 4")).actor_role.name).to eq("source")
    end

    it "normalizes platform names correctly" do
      entities["disseminators"] = [
        { "platform" => "facebook", "name" => "Account 1", "urls" => [] },
        { "platform" => "TWITTER", "name" => "Account 2", "urls" => [] },
        { "platform" => "you tube", "name" => "Account 3", "urls" => [] }
      ]

      service.call

      expect(Platform.find_by(name: "Facebook")).to be_present
      expect(Platform.find_by(name: "Twitter")).to be_present
      expect(Platform.find_by(name: "You Tube")).to be_present
    end

    it "wraps all operations in a transaction" do
      # Force an error after topics are created
      allow(fact_check).to receive(:fact_check_actors).and_raise(StandardError, "Simulated error")

      expect { service.call }.to raise_error(StandardError, "Simulated error")

      # Topics should be rolled back
      fact_check.reload
      expect(fact_check.topics.count).to eq(0)
      expect(fact_check.ai_enriched).to be(false)
    end

    it "returns the fact check" do
      result = service.call
      expect(result).to eq(fact_check)
    end
  end
end
