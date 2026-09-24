class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :group

  enum :role, { player: 0, host: 1 }

  validates :user_id, uniqueness: { scope: :group_id }
  validates :total_points, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
