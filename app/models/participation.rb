class Participation < ApplicationRecord
  belongs_to :user
  belongs_to :round

  after_create_commit -> { broadcast_refresh_later_to round }

  validates :user_id, uniqueness: { scope: :round_id }
  validates :points, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
