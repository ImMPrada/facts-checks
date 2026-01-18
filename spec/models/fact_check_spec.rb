require 'rails_helper'

RSpec.describe FactCheck, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:source_url) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:veredict) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:veredict) }
    it { is_expected.to belong_to(:publication_date).optional }

    it { is_expected.to have_many(:fact_check_topics).dependent(:destroy) }
    it { is_expected.to have_many(:topics).through(:fact_check_topics) }

    it { is_expected.to have_many(:fact_check_actors).dependent(:destroy) }
    it { is_expected.to have_many(:actors).through(:fact_check_actors) }

    it { is_expected.to have_many(:fact_check_disseminators).dependent(:destroy) }
    it { is_expected.to have_many(:disseminators).through(:fact_check_disseminators) }
  end

  describe 'scopes' do
    let!(:veredict) { create(:veredict) }
    let!(:publication_date) { create(:publication_date) }
    let!(:undigested_fact) { create(:fact_check, veredict: veredict, digested: false) }
    let!(:digested_fact) { create(:fact_check, :digested, veredict: veredict) }
    let!(:fact_with_date) { create(:fact_check, :with_publication_date, veredict: veredict, publication_date: publication_date) }

    describe '.undigested' do
      it 'returns only undigested fact checks' do
        expect(FactCheck.undigested).to include(undigested_fact, fact_with_date)
        expect(FactCheck.undigested).not_to include(digested_fact)
      end
    end

    describe '.digested' do
      it 'returns only digested fact checks' do
        expect(FactCheck.digested).to include(digested_fact)
        expect(FactCheck.digested).not_to include(undigested_fact, fact_with_date)
      end
    end

    describe '.by_veredict' do
      it 'returns fact checks filtered by veredict' do
        other_veredict = create(:veredict)
        other_fact = create(:fact_check, veredict: other_veredict)

        facts = FactCheck.by_veredict(veredict)
        expect(facts).to include(undigested_fact, digested_fact, fact_with_date)
        expect(facts).not_to include(other_fact)
      end
    end

    describe '.by_publication_date' do
      it 'returns fact checks filtered by publication date' do
        other_date = create(:publication_date)
        other_fact = create(:fact_check, :with_publication_date, veredict: veredict, publication_date: other_date)

        facts = FactCheck.by_publication_date(publication_date)
        expect(facts).to include(fact_with_date)
        expect(facts).not_to include(other_fact)
      end
    end
  end

  describe '#mark_as_digested!' do
    let(:fact_check) { create(:fact_check, digested: false) }

    it 'marks the fact check as digested' do
      expect {
        fact_check.mark_as_digested!
      }.to change { fact_check.digested }.from(false).to(true)
    end
  end

  describe 'default values' do
    let(:fact_check) { create(:fact_check) }

    it 'has digested defaulting to false' do
      expect(fact_check.digested).to be false
    end
  end

  describe 'optional publication_date' do
    it 'can be created without a publication_date' do
      veredict = create(:veredict)
      fact_check = create(:fact_check, veredict: veredict, publication_date: nil)

      expect(fact_check).to be_valid
      expect(fact_check.publication_date).to be_nil
    end

    it 'can be created with a publication_date' do
      veredict = create(:veredict)
      publication_date = create(:publication_date)
      fact_check = create(:fact_check, veredict: veredict, publication_date: publication_date)

      expect(fact_check).to be_valid
      expect(fact_check.publication_date).to eq(publication_date)
    end
  end
end
