class FactCheckUrl < ApplicationRecord
  enum :source, { colombia_check: 0 }

  SOURCE_DOMAINS = {
    colombia_check: "https://colombiacheck.com"
  }.freeze

  validates :url, presence: true, uniqueness: true
  validates :source, presence: true
  validates :attempts, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :undigested, -> { where(digested: false) }
  scope :digested, -> { where(digested: true) }
  scope :by_source, ->(source) { where(source: source) }
  scope :with_errors, -> { where.not(last_error: nil) }

  def full_url
    domain = SOURCE_DOMAINS[source.to_sym]
    domain ? "#{domain}#{url}" : url
  end

  def mark_as_digested!
    update!(digested: true, digested_at: Time.current)
  end

  def mark_as_failed!(error_message)
    update!(
      attempts: attempts + 1,
      last_error: error_message
    )
  end
end
