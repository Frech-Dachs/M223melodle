class ProfilesController < ApplicationController
  before_action :require_login

  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(display_name: profile_params[:display_name])
      notice = "Profil gespeichert."
      new_email = profile_params[:email].to_s.strip.downcase
      if new_email.present? && new_email != @user.email
        @user.request_email_change!(new_email)
        notice = "Profil gespeichert. Bitte bestätige die neue E-Mail-Adresse über den Link, den wir dir gesendet haben."
      end
      redirect_to profile_path, notice: notice
    else
      render :edit, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  private

  def profile_params
    params.expect(user: [ :display_name, :email ])
  end
end
