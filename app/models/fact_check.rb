class FactCheck < ApplicationRecord
  belongs_to :veredict
  belongs_to :publication_date, optional: true

  has_many :fact_check_topics, dependent: :destroy
  has_many :topics, through: :fact_check_topics

  has_many :fact_check_actors, dependent: :destroy
  has_many :actors, through: :fact_check_actors

  has_many :fact_check_disseminators, dependent: :destroy
  has_many :disseminators, through: :fact_check_disseminators

  validates :source_url, presence: true
  validates :title, presence: true
  validates :veredict, presence: true

  scope :digested, -> { where(digested: true) }
  scope :undigested, -> { where(digested: false) }
  scope :by_veredict, ->(veredict) { where(veredict: veredict) }
  scope :by_publication_date, ->(publication_date) { where(publication_date: publication_date) }

  def mark_as_digested!
    update!(digested: true)
  end
end
