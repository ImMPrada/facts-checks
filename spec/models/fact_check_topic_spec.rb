require 'rails_helper'

RSpec.describe FactCheckTopic, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:fact_check) }
    it { is_expected.to validate_presence_of(:topic) }

    it 'validates uniqueness of topic_id scoped to fact_check_id' do
      fact_check_topic = create(:fact_check_topic)
      duplicate = build(:fact_check_topic, fact_check: fact_check_topic.fact_check, topic: fact_check_topic.topic)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:topic_id]).to include('has already been taken')
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:fact_check) }
    it { is_expected.to belong_to(:topic) }
  end

  describe 'database constraints' do
    it 'enforces unique index on fact_check_id and topic_id' do
      fact_check_topic = create(:fact_check_topic)
      duplicate = build(:fact_check_topic, fact_check: fact_check_topic.fact_check, topic: fact_check_topic.topic)

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
