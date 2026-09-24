class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :group

  enum :role, { player: 0, host: 1 }

  validates :user_id, uniqueness: { scope: :group_id }
end
