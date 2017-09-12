class Topic < ApplicationRecord
  validates :book, :quote, presence: true

  has_many :comments
  belongs_to :publisher, required: false

  # For testing filter.
  def self.search(string)
    str = "%#{string}%"
    where('character LIKE ? OR book LIKE ?', str, str)
  end
end
