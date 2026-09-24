class User < ApplicationRecord
  has_secure_password

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :display_name, with: ->(name) { name.strip }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :display_name, presence: true, length: { maximum: 30 }
  validates :password, length: { minimum: 12 }, allow_nil: true
end
