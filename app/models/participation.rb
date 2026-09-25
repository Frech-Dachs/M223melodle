class Participation < ApplicationRecord
  belongs_to :user
  belongs_to :round

  # Others see who is done; the player's own progress does not need a broadcast.
  after_save_commit -> { broadcast_refresh_later_to round }, if: :saved_change_to_finished?

  validates :user_id, uniqueness: { scope: :round_id }
  validates :points, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
