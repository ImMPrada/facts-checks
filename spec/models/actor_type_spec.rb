require 'rails_helper'

RSpec.describe ActorType, type: :model do
  describe 'validations' do
    subject { build(:actor_type) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:actors).dependent(:restrict_with_error) }
  end

  describe 'database constraints' do
    it 'enforces unique index on name' do
      actor_type = create(:actor_type, name: 'Person')
      duplicate = build(:actor_type, name: 'Person')

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
