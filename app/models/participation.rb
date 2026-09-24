class Participation < ApplicationRecord
  belongs_to :user
  belongs_to :round

  validates :user_id, uniqueness: { scope: :round_id }
  validates :points, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
