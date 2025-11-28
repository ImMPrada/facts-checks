require 'rails_helper'

RSpec.describe FactCheckUrl, type: :model do
  describe 'validations' do
    subject { build(:fact_check_url) }

    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_uniqueness_of(:url) }
    it { is_expected.to validate_numericality_of(:attempts).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:source).with_values(colombia_check: 0) }

    it 'can be created with colombia_check source' do
      fact_check_url = create(:fact_check_url, source: :colombia_check)
      expect(fact_check_url.source).to eq('colombia_check')
      expect(fact_check_url.colombia_check?).to be true
    end
  end

  describe 'scopes' do
    let!(:undigested_url) { create(:fact_check_url, digested: false) }
    let!(:digested_url) { create(:fact_check_url, :digested) }
    let!(:error_url) { create(:fact_check_url, :with_error) }

    describe '.undigested' do
      it 'returns only undigested URLs' do
        expect(FactCheckUrl.undigested).to include(undigested_url, error_url)
        expect(FactCheckUrl.undigested).not_to include(digested_url)
      end
    end

    describe '.digested' do
      it 'returns only digested URLs' do
        expect(FactCheckUrl.digested).to include(digested_url)
        expect(FactCheckUrl.digested).not_to include(undigested_url, error_url)
      end
    end

    describe '.by_source' do
      it 'returns URLs filtered by source' do
        urls = FactCheckUrl.by_source(:colombia_check)
        expect(urls).to include(undigested_url, digested_url, error_url)
      end
    end

    describe '.with_errors' do
      it 'returns only URLs with errors' do
        expect(FactCheckUrl.with_errors).to include(error_url)
        expect(FactCheckUrl.with_errors).not_to include(undigested_url, digested_url)
      end
    end
  end

  describe '#mark_as_digested!' do
    let(:fact_check_url) { create(:fact_check_url, digested: false, digested_at: nil) }

    it 'marks the URL as digested' do
      expect {
        fact_check_url.mark_as_digested!
      }.to change { fact_check_url.digested }.from(false).to(true)
    end

    it 'sets digested_at timestamp' do
      frozen_time = Time.zone.parse('2025-01-15 12:00:00')
      Timecop.freeze(frozen_time) do
        fact_check_url.mark_as_digested!
        expect(fact_check_url.digested_at).to eq(frozen_time)
      end
    end
  end

  describe '#mark_as_failed!' do
    let(:fact_check_url) { create(:fact_check_url, attempts: 0, last_error: nil) }
    let(:error_message) { 'Network timeout' }

    it 'increments the attempts counter' do
      expect {
        fact_check_url.mark_as_failed!(error_message)
      }.to change { fact_check_url.attempts }.from(0).to(1)
    end

    it 'stores the error message' do
      fact_check_url.mark_as_failed!(error_message)
      expect(fact_check_url.last_error).to eq(error_message)
    end

    it 'can be called multiple times' do
      fact_check_url.mark_as_failed!('First error')
      fact_check_url.mark_as_failed!('Second error')
      expect(fact_check_url.attempts).to eq(2)
      expect(fact_check_url.last_error).to eq('Second error')
    end
  end

  describe '#full_url' do
    context 'when source is colombia_check' do
      let(:fact_check_url) { create(:fact_check_url, url: '/chequeos/test-article', source: :colombia_check) }

      it 'returns the full URL with domain' do
        expect(fact_check_url.full_url).to eq('https://colombiacheck.com/chequeos/test-article')
      end
    end

    context 'when URL is a path without leading slash' do
      let(:fact_check_url) { create(:fact_check_url, url: 'chequeos/another-article', source: :colombia_check) }

      it 'concatenates domain and path' do
        expect(fact_check_url.full_url).to eq('https://colombiacheck.comchequeos/another-article')
      end
    end
  end

  describe 'default values' do
    let(:fact_check_url) { create(:fact_check_url) }

    it 'has digested defaulting to false' do
      expect(fact_check_url.digested).to be false
    end

    it 'has attempts defaulting to 0' do
      expect(fact_check_url.attempts).to eq(0)
    end

    it 'has digested_at defaulting to nil' do
      expect(fact_check_url.digested_at).to be_nil
    end

    it 'has last_error defaulting to nil' do
      expect(fact_check_url.last_error).to be_nil
    end
  end
end
