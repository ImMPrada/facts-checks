require 'rails_helper'

RSpec.describe FactCheckDisseminator, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:fact_check) }
    it { is_expected.to validate_presence_of(:disseminator) }

    it 'validates uniqueness of disseminator_id scoped to fact_check_id' do
      fact_check_disseminator = create(:fact_check_disseminator)
      duplicate = build(:fact_check_disseminator,
                        fact_check: fact_check_disseminator.fact_check,
                        disseminator: fact_check_disseminator.disseminator)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:disseminator_id]).to include('has already been taken')
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:fact_check) }
    it { is_expected.to belong_to(:disseminator) }
  end

  describe 'database constraints' do
    it 'enforces unique index on fact_check_id and disseminator_id' do
      fact_check_disseminator = create(:fact_check_disseminator)
      duplicate = build(:fact_check_disseminator,
                        fact_check: fact_check_disseminator.fact_check,
                        disseminator: fact_check_disseminator.disseminator)

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
