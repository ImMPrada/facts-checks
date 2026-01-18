require 'rails_helper'

RSpec.describe Topic, type: :model do
  describe 'validations' do
    subject { build(:topic) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:fact_check_topics).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:fact_checks).through(:fact_check_topics) }
  end

  describe 'database constraints' do
    it 'enforces unique index on name' do
      topic = create(:topic, name: 'Politics')
      duplicate = build(:topic, name: 'Politics')

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
