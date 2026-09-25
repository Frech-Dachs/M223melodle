class Group < ApplicationRecord
  class Full < StandardError; end
  class AlreadyMember < StandardError; end

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :scores, dependent: :destroy
  has_many :activities, dependent: :destroy
  has_many :songs, dependent: :destroy
  has_many :rounds, dependent: :destroy

  before_validation :generate_invite_code, on: :create

  validates :name, presence: true, length: { maximum: 50 }
  validates :invite_code, presence: true, uniqueness: true
  validates :member_limit, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  def full?
    memberships.count >= member_limit
  end

  # Creates a group with its host in one transaction.
  def self.create_with_host!(attributes, host)
    transaction do
      group = create!(attributes)
      group.memberships.create!(user: host, role: :host)
      group.scores.create!(user: host)
      Activity.record!(group: group, action: "group_created", actor: host)
      group
    end
  end

  # Adds a player. Runs in a write transaction (SQLite: BEGIN IMMEDIATE), so two users
  # racing for the last seat are serialised: the second one sees the group as full.
  def self.join!(invite_code, user)
    transaction do
      group = find_by!(invite_code: invite_code.to_s.strip.upcase)
      raise AlreadyMember if group.memberships.exists?(user_id: user.id)
      raise Full if group.full?
      group.memberships.create!(user: user, role: :player)
      group.scores.find_or_create_by!(user: user)
      Activity.record!(group: group, action: "member_joined", actor: user)
      group
    end
  rescue ActiveRecord::RecordNotUnique
    raise AlreadyMember
  end

  def remove_member!(membership)
    transaction do
      scores.where(user_id: membership.user_id).destroy_all
      membership.destroy!
      Activity.record!(group: self, action: "member_removed", name: membership.user.display_name)
    end
  end

  private

  def generate_invite_code
    self.invite_code ||= loop do
      code = SecureRandom.alphanumeric(8).upcase
      break code unless Group.exists?(invite_code: code)
    end
  end
end
