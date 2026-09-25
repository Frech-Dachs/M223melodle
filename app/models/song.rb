class Song < ApplicationRecord
  belongs_to :group
  belongs_to :added_by, class_name: "User"
  has_many :rounds, dependent: :restrict_with_error

  scope :search, ->(query) {
    next all if query.blank?
    pattern = "%#{sanitize_sql_like(query.strip)}%"
    where("title LIKE :q OR artist LIKE :q", q: pattern)
  }

  normalizes :title, :artist, :audio_url, with: ->(value) { value.strip }

  validates :title, :artist, :audio_url, presence: true
  validates :title, :artist, length: { maximum: 100 }
  validates :audio_url, length: { maximum: 500 }
  validates :audio_url, format: { with: %r{\A(/|https?://)\S+\z}, message: "muss ein Pfad (/audio/…) oder eine http(s)-URL sein" }, allow_blank: true
  validates :title, uniqueness: { scope: [ :group_id, :artist ] }
end
