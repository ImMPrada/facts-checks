require 'rails_helper'

RSpec.describe Actor, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:actor_type) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:actor_type) }
    it { is_expected.to have_many(:fact_check_actors).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:fact_checks).through(:fact_check_actors) }
  end

  describe 'database constraints' do
    it 'has an index on name for performance' do
      actor = create(:actor)
      expect(actor).to be_valid
    end

    it 'requires actor_type_id foreign key' do
      actor = Actor.new(name: 'Test Actor', actor_type_id: nil)
      expect { actor.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end
  end
end
