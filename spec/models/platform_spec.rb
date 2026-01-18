require 'rails_helper'

RSpec.describe Platform, type: :model do
  describe 'validations' do
    subject { build(:platform) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:disseminators).dependent(:restrict_with_error) }
  end

  describe 'database constraints' do
    it 'enforces unique index on name' do
      platform = create(:platform, name: 'Facebook')
      duplicate = build(:platform, name: 'Facebook')

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
