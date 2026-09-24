class JoinsController < ApplicationController
  before_action :require_login

  def new
  end

  def create
    group = Group.join!(params[:invite_code], current_user)
    redirect_to group, notice: "Du bist der Gruppe «#{group.name}» beigetreten."
  rescue ActiveRecord::RecordNotFound
    join_failed "Diesen Einladungscode gibt es nicht."
  rescue Group::Full
    join_failed "Diese Gruppe ist voll."
  rescue Group::AlreadyMember
    join_failed "Du bist bereits Mitglied dieser Gruppe."
  end

  private

  def join_failed(message)
    flash.now[:alert] = message
    render :new, status: :unprocessable_entity
  end
end
