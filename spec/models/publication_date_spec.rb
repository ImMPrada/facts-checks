require 'rails_helper'

RSpec.describe PublicationDate, type: :model do
  describe 'validations' do
    subject { build(:publication_date) }

    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_uniqueness_of(:date).case_insensitive }
  end

  describe 'associations' do
    it { is_expected.to have_many(:fact_checks).dependent(:restrict_with_error) }
  end

  describe 'database constraints' do
    it 'enforces unique index on date' do
      publication_date = create(:publication_date, date: "2025-01-15")
      duplicate = build(:publication_date, date: "2025-01-15")

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
