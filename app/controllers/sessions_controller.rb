class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.authenticate_by(email: params[:email].to_s.strip.downcase, password: params[:password])
    if user
      reset_session
      session[:user_id] = user.id
      redirect_to dashboard_path, notice: "Erfolgreich angemeldet."
    else
      flash.now[:alert] = "E-Mail oder Passwort ist falsch."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to new_session_path, notice: "Du wurdest abgemeldet."
  end
end
