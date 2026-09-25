class RoundsController < ApplicationController
  before_action :require_login

  def create
    group = policy_scope(Group).find(params[:group_id])
    song = params[:song_id].present? ? group.songs.find(params[:song_id]) : group.songs.order("RANDOM()").first
    return redirect_to group_songs_path(group), alert: "Füge zuerst Songs hinzu." unless song

    authorize Round.new(group: group, song: song)
    round = Round.start!(group, song, current_user)
    redirect_to round, notice: "Runde gestartet."
  rescue Round::AlreadyActive
    redirect_to group.rounds.active.first || group, alert: "In dieser Gruppe läuft bereits eine Runde."
  end

  def show
    @round = Round.where(group_id: current_user.group_ids).find(params[:id]) # other groups' rounds: 404
    authorize @round
    @group = @round.group
    @participation = @round.participation_for(current_user)
    @participations = @round.participations.where(finished: true).includes(:user).order(points: :desc)
    @still_playing = @group.users.where.not(id: @participations.map(&:user_id)).order(:display_name)
  end

  def finish
    round = Round.where(group_id: current_user.group_ids).find(params[:id])
    authorize round, :finish?
    round.finish!
    redirect_to round, notice: "Runde beendet."
  end
end
