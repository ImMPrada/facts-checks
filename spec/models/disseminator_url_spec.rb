require 'rails_helper'

RSpec.describe DisseminatorUrl, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_presence_of(:disseminator) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:disseminator) }
  end

  describe 'database constraints' do
    it 'requires disseminator_id foreign key' do
      disseminator_url = DisseminatorUrl.new(url: 'https://example.com', disseminator_id: nil)
      expect { disseminator_url.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end
  end
end
