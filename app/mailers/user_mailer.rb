class UserMailer < ApplicationMailer
  def email_confirmation(user)
    @user = user
    @token = user.generate_token_for(:email_confirmation)
    mail to: user.unconfirmed_email, subject: "Melodle: E-Mail-Adresse bestätigen"
  end
end
