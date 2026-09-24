class PasswordsController < ApplicationController
  before_action :require_login

  def edit
  end

  def update
    user = current_user
    if !user.authenticate(params[:current_password].to_s)
      flash.now[:alert] = "Das aktuelle Passwort ist falsch."
      render :edit, status: :unprocessable_entity
    elsif user.update(password_params)
      redirect_to profile_path, notice: "Passwort geändert."
    else
      @user = user
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.expect(user: [ :password, :password_confirmation ])
  end
end
