require 'rails_helper'

RSpec.describe FactCheck::CreationService do
  let(:params) do
    {
      source_url: 'https://example.com/fact-check',
      title: 'Test Fact Check',
      reasoning: 'This is a detailed explanation',
      veredict: 'true',
      publication_date: "2025-01-15"
    }
  end
  let(:service) { described_class.new(params) }

  describe '#initialize' do
    it 'accepts params' do
      expect(service).to be_a(FactCheck::CreationService)
    end

    it 'initializes fact_check as nil' do
      expect(service.fact_check).to be_nil
    end
  end

  describe '#build' do
    it 'creates a FactCheck instance' do
      service.build
      expect(service.fact_check).to be_a(FactCheck)
    end

    it 'sets source_url from params' do
      service.build
      expect(service.fact_check.source_url).to eq('https://example.com/fact-check')
    end

    it 'sets title from params' do
      service.build
      expect(service.fact_check.title).to eq('Test Fact Check')
    end

    it 'sets reasoning from params' do
      service.build
      expect(service.fact_check.reasoning).to eq('This is a detailed explanation')
    end

    context 'with veredict as string' do
      it 'creates a new Veredict' do
        expect {
          service.build
        }.to change { Veredict.count }.by(1)
      end

      it 'uppercases the veredict name' do
        service.build
        expect(service.fact_check.veredict.name).to eq('TRUE')
      end

      it 'assigns the veredict to fact_check' do
        service.build
        expect(service.fact_check.veredict).to be_a(Veredict)
        expect(service.fact_check.veredict.name).to eq('TRUE')
      end
    end

    context 'with existing veredict' do
      let!(:existing_veredict) { Veredict.create!(name: 'TRUE') }

      it 'does not create a new Veredict' do
        expect {
          service.build
        }.not_to change { Veredict.count }
      end

      it 'uses the existing veredict' do
        service.build
        expect(service.fact_check.veredict).to eq(existing_veredict)
      end
    end

    context 'with veredict as Veredict object' do
      let!(:veredict_object) { Veredict.create!(name: 'FALSE') }
      let(:params) do
        {
          source_url: 'https://example.com/fact-check',
          title: 'Test Fact Check',
          reasoning: 'This is a detailed explanation',
          veredict: veredict_object,
          publication_date: Date.new(2025, 1, 15)
        }
      end

      it 'uses the provided Veredict object' do
        service.build
        expect(service.fact_check.veredict).to eq(veredict_object)
      end

      it 'does not create a new Veredict' do
        expect {
          service.build
        }.not_to change { Veredict.count }
      end
    end

    context 'with nil veredict' do
      let(:params) do
        {
          source_url: 'https://example.com/fact-check',
          title: 'Test Fact Check',
          reasoning: 'This is a detailed explanation',
          veredict: nil,
          publication_date: Date.new(2025, 1, 15)
        }
      end

      it 'sets veredict to nil' do
        service.build
        expect(service.fact_check.veredict).to be_nil
      end
    end

    context 'with publication_date as string' do
      it 'creates a new PublicationDate' do
        expect {
          service.build
        }.to change { PublicationDate.count }.by(1)
      end

      it 'assigns the publication_date to fact_check' do
        service.build
        expect(service.fact_check.publication_date).to be_a(PublicationDate)
        expect(service.fact_check.publication_date.date).to eq("2025-01-15")
      end
    end

    context 'with existing publication_date' do
      let!(:existing_date) { PublicationDate.create!(date: "2025-01-15") }

      it 'does not create a new PublicationDate' do
        expect {
          service.build
        }.not_to change { PublicationDate.count }
      end

      it 'uses the existing publication_date' do
        service.build
        expect(service.fact_check.publication_date).to eq(existing_date)
      end
    end

    context 'with publication_date as PublicationDate object' do
      let!(:publication_date_object) { PublicationDate.create!(date: "2025-02-20") }
      let(:params) do
        {
          source_url: 'https://example.com/fact-check',
          title: 'Test Fact Check',
          reasoning: 'This is a detailed explanation',
          veredict: 'true',
          publication_date: publication_date_object
        }
      end

      it 'uses the provided PublicationDate object' do
        service.build
        expect(service.fact_check.publication_date).to eq(publication_date_object)
      end

      it 'does not create a new PublicationDate' do
        expect {
          service.build
        }.not_to change { PublicationDate.count }
      end
    end

    context 'with nil publication_date' do
      let(:params) do
        {
          source_url: 'https://example.com/fact-check',
          title: 'Test Fact Check',
          reasoning: 'This is a detailed explanation',
          veredict: 'true',
          publication_date: nil
        }
      end

      it 'sets publication_date to nil' do
        service.build
        expect(service.fact_check.publication_date).to be_nil
      end
    end

    context 'with lowercase veredict' do
      let(:params) do
        {
          source_url: 'https://example.com/fact-check',
          title: 'Test Fact Check',
          reasoning: 'This is a detailed explanation',
          veredict: 'mostly true',
          publication_date: "2025-01-15"
        }
      end

      it 'uppercases the entire veredict string' do
        service.build
        expect(service.fact_check.veredict.name).to eq('MOSTLY TRUE')
      end
    end
  end

  describe '#save!' do
    before do
      service.build
    end

    it 'saves the fact_check to the database' do
      expect {
        service.save!
      }.to change { FactCheck.count }.by(1)
    end

    it 'returns the saved fact_check' do
      result = service.save!
      expect(result).to be_a(FactCheck)
      expect(result).to be_persisted
    end

    it 'returns the same object as fact_check' do
      result = service.save!
      expect(result).to eq(service.fact_check)
    end

    it 'persists all attributes' do
      saved = service.save!
      reloaded = FactCheck.find(saved.id)

      expect(reloaded.source_url).to eq('https://example.com/fact-check')
      expect(reloaded.title).to eq('Test Fact Check')
      expect(reloaded.reasoning).to eq('This is a detailed explanation')
      expect(reloaded.veredict.name).to eq('TRUE')
      expect(reloaded.publication_date.date).to eq("2025-01-15")
    end
  end

  describe 'full workflow' do
    it 'builds and saves a complete fact check' do
      service.build
      saved = service.save!

      expect(saved).to be_persisted
      expect(saved.source_url).to eq('https://example.com/fact-check')
      expect(saved.veredict.name).to eq('TRUE')
      expect(saved.publication_date.date).to eq("2025-01-15")
    end

    it 'reuses existing veredict and publication_date' do
      # First fact check
      first_service = described_class.new(params)
      first_service.build
      first_service.save!

      # Second fact check with same veredict and date
      second_params = params.merge(
        source_url: 'https://example.com/different-fact',
        title: 'Another Fact Check'
      )
      second_service = described_class.new(second_params)

      expect {
        second_service.build
        second_service.save!
      }.to change { FactCheck.count }.by(1)

      expect(Veredict.count).to eq(1)
      expect(PublicationDate.count).to eq(1)
    end
  end
end
