class Group < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :scores, dependent: :destroy
  has_many :songs, dependent: :destroy
  has_many :rounds, dependent: :destroy

  before_validation :generate_invite_code, on: :create

  validates :name, presence: true, length: { maximum: 50 }
  validates :invite_code, presence: true, uniqueness: true
  validates :member_limit, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  def full?
    memberships.count >= member_limit
  end

  private

  def generate_invite_code
    self.invite_code ||= loop do
      code = SecureRandom.alphanumeric(8).upcase
      break code unless Group.exists?(invite_code: code)
    end
  end
end
