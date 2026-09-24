class Song < ApplicationRecord
  belongs_to :group
  belongs_to :added_by, class_name: "User"
  has_many :rounds, dependent: :restrict_with_error

  normalizes :title, :artist, :audio_url, with: ->(value) { value.strip }

  validates :title, :artist, :audio_url, presence: true
  validates :title, uniqueness: { scope: [ :group_id, :artist ] }
end
