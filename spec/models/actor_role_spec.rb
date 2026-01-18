require 'rails_helper'

RSpec.describe ActorRole, type: :model do
  describe 'validations' do
    subject { build(:actor_role) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:fact_check_actors).dependent(:restrict_with_error) }
  end

  describe 'database constraints' do
    it 'enforces unique index on name' do
      actor_role = create(:actor_role, name: 'Target')
      duplicate = build(:actor_role, name: 'Target')

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
