require 'rails_helper'

RSpec.describe FactCheckActor, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:fact_check) }
    it { is_expected.to validate_presence_of(:actor) }
    it { is_expected.to validate_presence_of(:actor_role) }

    it 'validates uniqueness of actor_id scoped to fact_check_id and actor_role_id' do
      fact_check_actor = create(:fact_check_actor)
      duplicate = build(:fact_check_actor,
                        fact_check: fact_check_actor.fact_check,
                        actor: fact_check_actor.actor,
                        actor_role: fact_check_actor.actor_role)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:actor_id]).to include('has already been taken')
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:fact_check) }
    it { is_expected.to belong_to(:actor) }
    it { is_expected.to belong_to(:actor_role) }
  end

  describe 'database constraints' do
    it 'enforces unique index on fact_check_id, actor_id, and actor_role_id' do
      fact_check_actor = create(:fact_check_actor)
      duplicate = build(:fact_check_actor,
                        fact_check: fact_check_actor.fact_check,
                        actor: fact_check_actor.actor,
                        actor_role: fact_check_actor.actor_role)

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
