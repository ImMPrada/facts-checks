require 'rails_helper'

RSpec.describe Disseminator, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:platform) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:platform) }
    it { is_expected.to have_many(:disseminator_urls).dependent(:destroy) }
    it { is_expected.to have_many(:fact_check_disseminators).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:fact_checks).through(:fact_check_disseminators) }
  end

  describe 'database constraints' do
    it 'requires platform_id foreign key' do
      disseminator = Disseminator.new(name: 'Test Disseminator', platform_id: nil)
      expect { disseminator.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end
  end
end
