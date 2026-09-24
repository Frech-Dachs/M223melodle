class EmailConfirmationsController < ApplicationController
  def show
    user = User.find_by_token_for(:email_confirmation, params[:token])
    if user&.confirm_email_change!
      redirect_to(logged_in? ? profile_path : new_session_path, notice: "E-Mail-Adresse bestätigt.")
    else
      redirect_to root_path, alert: "Der Bestätigungslink ist ungültig oder abgelaufen."
    end
  rescue ActiveRecord::RecordInvalid
    redirect_to root_path, alert: "Diese E-Mail-Adresse ist bereits vergeben."
  end
end
