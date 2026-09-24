class User < ApplicationRecord
  has_secure_password

  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :participations, dependent: :destroy

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :display_name, with: ->(name) { name.strip }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :display_name, presence: true, length: { maximum: 30 }
  validates :password, length: { minimum: 12 }, allow_nil: true
end
