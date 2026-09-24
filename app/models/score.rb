class Score < ApplicationRecord
  belongs_to :user
  belongs_to :group

  validates :user_id, uniqueness: { scope: :group_id }
  validates :total_points, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :leaderboard, -> { order(total_points: :desc).includes(:user) }

  # Atomic increment (UPDATE ... SET total_points = total_points + n), safe against lost updates.
  def add_points!(points)
    self.class.update_counters(id, total_points: points)
  end
end
