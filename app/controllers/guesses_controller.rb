class GuessesController < ApplicationController
  before_action :require_login

  def create
    round = Round.where(group_id: current_user.group_ids).find(params[:round_id])
    authorize round, :guess?

    case round.guess!(current_user, params[:guess])
    when :correct then redirect_to round, notice: "Richtig! Du bekommst Punkte."
    when :wrong then redirect_to round, alert: "Leider falsch, hier ist ein längerer Ausschnitt."
    when :out_of_tries then redirect_to round, alert: "Leider falsch, du hast keine Versuche mehr."
    when :already then redirect_to round, alert: "Du hast diese Runde schon gespielt."
    else redirect_to round, alert: "Die Runde ist bereits beendet."
    end
  end
end
