class User < ApplicationRecord
  has_secure_password

  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :scores, dependent: :destroy
  has_many :participations, dependent: :destroy

  generates_token_for :email_confirmation, expires_in: 1.hour do
    unconfirmed_email
  end

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :display_name, with: ->(name) { name.strip }
  normalizes :unconfirmed_email, with: ->(email) { email.strip.downcase.presence }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :display_name, presence: true, length: { maximum: 30 }
  validates :unconfirmed_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  validates :password, length: { minimum: 12 }, allow_nil: true

  # Stores the new address and mails a confirmation link in one transaction:
  # if the mail cannot be built/sent, the change is rolled back.
  def request_email_change!(new_email)
    self.unconfirmed_email = new_email
    unless valid? && unconfirmed_email_available?
      errors.add(:unconfirmed_email, :taken) if errors[:unconfirmed_email].empty? && unconfirmed_email.present?
      raise ActiveRecord::RecordInvalid, self
    end
    transaction do
      save!
      UserMailer.email_confirmation(self).deliver_now
    end
  end

  def confirm_email_change!
    return false if unconfirmed_email.blank?
    update!(email: unconfirmed_email, unconfirmed_email: nil)
  end

  private

  def unconfirmed_email_available?
    unconfirmed_email.blank? || !User.where.not(id: id).exists?(email: unconfirmed_email)
  end
end
