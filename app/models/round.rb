class Round < ApplicationRecord
  belongs_to :group
  belongs_to :song
  belongs_to :started_by, class_name: "User"
  has_many :participations, dependent: :destroy

  enum :status, { active: 0, finished: 1 }

  validates :started_at, presence: true
end
